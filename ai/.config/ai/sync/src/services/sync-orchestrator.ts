import * as path from 'path';
import { execSync } from 'child_process';
import type { 
  ContextFile, 
  FileOperationResult, 
  SyncResult 
} from '../types/sync';
import { ContentMerger } from './content-merger';
import { ContextFileDetector } from './context-file-detector';
import { FileOperations } from '../utils/file-operations';

export class SyncOrchestrator {
  constructor(
    private readonly contentMerger: ContentMerger,
    private readonly detector: ContextFileDetector,
    private readonly fileOps: FileOperations
  ) {}

  async syncWindsurfToClaude(projectRoot: string): Promise<SyncResult> {
    const detectionResult = await this.detector.detectContextFiles(projectRoot);
    if (!detectionResult.success || !detectionResult.data) {
      return { filesProcessed: 0, filesUpdated: 0, success: false };
    }

    const contextFiles = detectionResult.data;
    const windsurfFiles = contextFiles.filter(f => f.type === 'windsurf');
    const workflowFiles = contextFiles.filter(f => f.type === 'windsurf-workflow');
    
    if (windsurfFiles.length === 0 && workflowFiles.length === 0) {
      return { filesProcessed: 0, filesUpdated: 0, success: true };
    }

    let filesProcessed = 0;
    let filesUpdated = 0;
    const updatedFiles: string[] = [];
    const skippedFiles: string[] = [];

    // Sync Windsurf rules → Claude context
    for (const windsurfFile of windsurfFiles) {
      filesProcessed++;
      const fileName = path.basename(windsurfFile.filePath);
      
      const claudeFilePath = this.getCorrespondingClaudeFile(windsurfFile.filePath);
      
      const syncResult = await this.syncSingleWindsurfToClaude(
        windsurfFile, 
        claudeFilePath
      );
      
      if (syncResult) {
        filesUpdated++;
        updatedFiles.push(fileName);
      } else {
        skippedFiles.push(fileName);
      }
    }

    // Sync Windsurf workflows → Claude commands
    for (const workflowFile of workflowFiles) {
      filesProcessed++;
      const fileName = path.basename(workflowFile.filePath);
      
      const commandFilePath = this.getCorrespondingCommandFile(workflowFile.filePath);
      
      const syncResult = await this.syncSingleWorkflowToCommand(
        workflowFile, 
        commandFilePath
      );
      
      if (syncResult) {
        filesUpdated++;
        updatedFiles.push(fileName);
      } else {
        skippedFiles.push(fileName);
      }
    }

    // Summary output
    if (updatedFiles.length > 0) {
      console.error(`✓ Updated: ${updatedFiles.join(', ')}`);
    }
    if (skippedFiles.length > 0) {
      console.error(`→ Skipped: ${skippedFiles.length} files`);
    }

    return { filesProcessed, filesUpdated, success: true };
  }

  async syncClaudeToWindsurf(
    modifiedFilePath: string, 
    projectRoot: string
  ): Promise<SyncResult> {
    // Only sync if the modified file is a context file or command
    if (!this.isContextFile(modifiedFilePath) && !this.isCommandFile(modifiedFilePath)) {
      return { filesProcessed: 0, filesUpdated: 0, success: true };
    }

    const readResult = await this.fileOps.readFile(modifiedFilePath);
    if (!readResult.success || !readResult.data) {
      return { filesProcessed: 0, filesUpdated: 0, success: false };
    }

    const statsResult = await this.fileOps.getFileStats(modifiedFilePath);
    if (!statsResult.success || !statsResult.data) {
      return { filesProcessed: 0, filesUpdated: 0, success: false };
    }

    // Determine file type
    const isCommand = this.isCommandFile(modifiedFilePath);
    const fileType = isCommand ? 'claude-command' : 'claude';

    const claudeFile: ContextFile = {
      content: readResult.data,
      filePath: modifiedFilePath,
      lastModified: statsResult.data.mtime,
      type: fileType as any
    };

    let syncResult: boolean;
    
    if (isCommand) {
      // Claude command → Windsurf workflow
      const workflowFilePath = this.getCorrespondingWorkflowFile(modifiedFilePath);
      syncResult = await this.syncSingleCommandToWorkflow(claudeFile, workflowFilePath);
    } else {
      // Claude context → Windsurf rule
      const windsurfFilePath = this.getCorrespondingWindsurfFile(modifiedFilePath);
      syncResult = await this.syncSingleClaudeToWindsurf(claudeFile, windsurfFilePath);
    }

    const filesUpdated = syncResult ? 1 : 0;
    console.error(`✓ Sync complete: ${filesUpdated}/1 files updated`);
    
    return { filesProcessed: 1, filesUpdated, success: true };
  }

  private async syncSingleWindsurfToClaude(
    windsurfFile: ContextFile, 
    claudeFilePath: string
  ): Promise<boolean> {
    const fileName = path.basename(windsurfFile.filePath);
    
    // Check if Claude file exists and compare sync metadata if available
    const claudeExists = await this.fileOps.fileExists(claudeFilePath);
    if (claudeExists) {
      const claudeReadResult = await this.fileOps.readFile(claudeFilePath);
      if (claudeReadResult.success && claudeReadResult.data) {
        const claudeSyncMetadata = this.detector.extractSyncMetadata(claudeReadResult.data);
        
        // If Claude file has sync metadata, use that for comparison
        if (claudeSyncMetadata && windsurfFile.syncMetadata) {
          if (claudeSyncMetadata.lastSyncTime >= windsurfFile.syncMetadata.lastSyncTime) {
            // Skip silently, handled in summary
            return false;
          }
        } else {
          // Fallback to file modification times, but be more lenient
          const claudeStatsResult = await this.fileOps.getFileStats(claudeFilePath);
          if (claudeStatsResult.success && claudeStatsResult.data) {
            const claudeModified = claudeStatsResult.data.mtime;
            const timeDiffMs = claudeModified.getTime() - windsurfFile.lastModified.getTime();
            
            // Only skip if Claude file is significantly newer (>5 seconds)
            if (timeDiffMs > 5000) {
              // Skip silently, handled in summary
              return false;
            }
          }
        }
      }
    }

    const metadata = this.detector.createSyncMetadata(windsurfFile.filePath);
    const mergeResult = this.contentMerger.mergeWindsurfToClaude(
      windsurfFile.content, 
      metadata
    );

    if (!mergeResult.success) {
      return false;
    }

    const writeResult = await this.fileOps.writeFile(
      claudeFilePath, 
      mergeResult.mergedContent
    );

    if (!writeResult.success) {
      return false;
    }

    // Run markdown lint on the created file
    await this.runMarkdownLint(claudeFilePath);
    
    return true;
  }

  private async syncSingleClaudeToWindsurf(
    claudeFile: ContextFile, 
    windsurfFilePath: string
  ): Promise<boolean> {
    const fileName = path.basename(claudeFile.filePath);
    
    // Check if Windsurf file exists and compare sync metadata if available
    const windsurfExists = await this.fileOps.fileExists(windsurfFilePath);
    if (windsurfExists) {
      const windsurfReadResult = await this.fileOps.readFile(windsurfFilePath);
      if (windsurfReadResult.success && windsurfReadResult.data) {
        // For Windsurf files, we need to extract sync metadata from the content after frontmatter
        const contentWithoutFrontmatter = this.contentMerger.removeFrontmatter(windsurfReadResult.data);
        const windsurfSyncMetadata = this.detector.extractSyncMetadata(contentWithoutFrontmatter);
        
        // If Windsurf file has sync metadata, use that for comparison
        if (windsurfSyncMetadata && claudeFile.syncMetadata) {
          if (windsurfSyncMetadata.lastSyncTime >= claudeFile.syncMetadata.lastSyncTime) {
            // Skip silently, handled in summary
            return false;
          }
        } else {
          // Fallback to file modification times, but be more lenient
          const windsurfStatsResult = await this.fileOps.getFileStats(windsurfFilePath);
          if (windsurfStatsResult.success && windsurfStatsResult.data) {
            const windsurfModified = windsurfStatsResult.data.mtime;
            const timeDiffMs = windsurfModified.getTime() - claudeFile.lastModified.getTime();
            
            // Only skip if Windsurf file is significantly newer (>5 seconds)
            if (timeDiffMs > 5000) {
              // Skip silently, handled in summary
              return false;
            }
          }
        }
      }
    }

    // Read existing Windsurf file to preserve frontmatter
    const existingWindsurfContent = await this.fileOps.fileExists(windsurfFilePath)
      ? (await this.fileOps.readFile(windsurfFilePath)).data
      : undefined;

    const metadata = this.detector.createSyncMetadata(claudeFile.filePath);
    const mergeResult = this.contentMerger.mergeClaudeToWindsurf(
      claudeFile.content, 
      metadata,
      existingWindsurfContent
    );

    if (!mergeResult.success) {
      return false;
    }

    const writeResult = await this.fileOps.writeFile(
      windsurfFilePath, 
      mergeResult.mergedContent
    );

    if (!writeResult.success) {
      return false;
    }

    // Run markdown lint on the created file
    await this.runMarkdownLint(windsurfFilePath);
    
    return true;
  }

  private async syncSingleWorkflowToCommand(
    workflowFile: ContextFile, 
    commandFilePath: string
  ): Promise<boolean> {
    const fileName = path.basename(workflowFile.filePath);
    
    // Check if command file exists and compare sync metadata if available
    const commandExists = await this.fileOps.fileExists(commandFilePath);
    if (commandExists) {
      const commandReadResult = await this.fileOps.readFile(commandFilePath);
      if (commandReadResult.success && commandReadResult.data) {
        const commandSyncMetadata = this.detector.extractSyncMetadata(commandReadResult.data);
        
        // If command file has sync metadata, use that for comparison
        if (commandSyncMetadata && workflowFile.syncMetadata) {
          if (commandSyncMetadata.lastSyncTime >= workflowFile.syncMetadata.lastSyncTime) {
            // Skip silently, handled in summary
            return false;
          }
        } else {
          // Fallback to file modification times, but be more lenient
          const commandStatsResult = await this.fileOps.getFileStats(commandFilePath);
          if (commandStatsResult.success && commandStatsResult.data) {
            const commandModified = commandStatsResult.data.mtime;
            const timeDiffMs = commandModified.getTime() - workflowFile.lastModified.getTime();
            
            // Only skip if command file is significantly newer (>5 seconds)
            if (timeDiffMs > 5000) {
              // Skip silently, handled in summary
              return false;
            }
          }
        }
      }
    }

    const metadata = this.detector.createSyncMetadata(workflowFile.filePath);
    const mergeResult = this.contentMerger.mergeWindsurfToClaude(
      workflowFile.content, 
      metadata
    );

    if (!mergeResult.success) {
      return false;
    }

    const writeResult = await this.fileOps.writeFile(
      commandFilePath, 
      mergeResult.mergedContent
    );

    if (!writeResult.success) {
      return false;
    }

    // Run markdown lint on the created file
    await this.runMarkdownLint(commandFilePath);
    
    return true;
  }

  private async syncSingleCommandToWorkflow(
    commandFile: ContextFile, 
    workflowFilePath: string
  ): Promise<boolean> {
    const fileName = path.basename(commandFile.filePath);
    
    // Check if workflow file exists and compare sync metadata if available
    const workflowExists = await this.fileOps.fileExists(workflowFilePath);
    if (workflowExists) {
      const workflowReadResult = await this.fileOps.readFile(workflowFilePath);
      if (workflowReadResult.success && workflowReadResult.data) {
        // For workflow files, we need to extract sync metadata from the content after frontmatter
        const contentWithoutFrontmatter = this.contentMerger.removeFrontmatter(workflowReadResult.data);
        const workflowSyncMetadata = this.detector.extractSyncMetadata(contentWithoutFrontmatter);
        
        // If workflow file has sync metadata, use that for comparison
        if (workflowSyncMetadata && commandFile.syncMetadata) {
          if (workflowSyncMetadata.lastSyncTime >= commandFile.syncMetadata.lastSyncTime) {
            // Skip silently, handled in summary
            return false;
          }
        } else {
          // Fallback to file modification times, but be more lenient
          const workflowStatsResult = await this.fileOps.getFileStats(workflowFilePath);
          if (workflowStatsResult.success && workflowStatsResult.data) {
            const workflowModified = workflowStatsResult.data.mtime;
            const timeDiffMs = workflowModified.getTime() - commandFile.lastModified.getTime();
            
            // Only skip if workflow file is significantly newer (>5 seconds)
            if (timeDiffMs > 5000) {
              // Skip silently, handled in summary
              return false;
            }
          }
        }
      }
    }

    // Read existing workflow file to preserve frontmatter
    const existingWorkflowContent = await this.fileOps.fileExists(workflowFilePath)
      ? (await this.fileOps.readFile(workflowFilePath)).data
      : undefined;

    const metadata = this.detector.createSyncMetadata(commandFile.filePath);
    const mergeResult = this.contentMerger.mergeClaudeToWindsurf(
      commandFile.content, 
      metadata,
      existingWorkflowContent,
      true // isWorkflow = true
    );

    if (!mergeResult.success) {
      return false;
    }

    const writeResult = await this.fileOps.writeFile(
      workflowFilePath, 
      mergeResult.mergedContent
    );

    if (!writeResult.success) {
      return false;
    }

    // Run markdown lint on the created file
    await this.runMarkdownLint(workflowFilePath);
    
    return true;
  }

  private getCorrespondingClaudeFile(windsurfFilePath: string): string {
    // Convert ./path/to/.windsurf/rules/FILENAME.md → ./path/to/FILENAME.md
    const fileName = path.basename(windsurfFilePath);
    
    // Remove .windsurf/rules from the path to get the Claude directory
    const windsurfDir = path.dirname(windsurfFilePath); // .../path/to/.windsurf/rules
    const windsurfParent = path.dirname(windsurfDir);   // .../path/to/.windsurf
    const claudeDir = path.dirname(windsurfParent);     // .../path/to
    
    return path.join(claudeDir, fileName);
  }

  private getCorrespondingWindsurfFile(claudeFilePath: string): string {
    // Convert ./path/to/FILENAME.md → ./path/to/.windsurf/rules/FILENAME.md
    const fileName = path.basename(claudeFilePath);
    const claudeDir = path.dirname(claudeFilePath);
    return path.join(claudeDir, '.windsurf', 'rules', fileName);
  }

  private getCorrespondingWorkflowFile(commandFilePath: string): string {
    // Convert ./path/to/.claude/commands/FILENAME.md → ./path/to/.windsurf/workflows/FILENAME.md
    const fileName = path.basename(commandFilePath);
    
    // Remove .claude/commands from the path to get the base directory
    const commandDir = path.dirname(commandFilePath); // .../path/to/.claude/commands
    const claudeParent = path.dirname(commandDir);    // .../path/to/.claude
    const baseDir = path.dirname(claudeParent);       // .../path/to
    
    return path.join(baseDir, '.windsurf', 'workflows', fileName);
  }

  private getCorrespondingCommandFile(workflowFilePath: string): string {
    // Convert ./path/to/.windsurf/workflows/FILENAME.md → ./path/to/.claude/commands/FILENAME.md
    const fileName = path.basename(workflowFilePath);
    
    // Remove .windsurf/workflows from the path to get the base directory
    const workflowDir = path.dirname(workflowFilePath); // .../path/to/.windsurf/workflows
    const windsurfParent = path.dirname(workflowDir);   // .../path/to/.windsurf
    const baseDir = path.dirname(windsurfParent);       // .../path/to
    
    return path.join(baseDir, '.claude', 'commands', fileName);
  }

  private findProjectRoot(filePath: string): string {
    let currentDir = path.dirname(filePath);
    
    // Walk up until we find .windsurf directory or hit filesystem root
    while (currentDir !== path.dirname(currentDir)) {
      const windsurfDir = path.join(currentDir, '.windsurf');
      if (require('fs').existsSync(windsurfDir)) {
        return currentDir;
      }
      currentDir = path.dirname(currentDir);
    }
    
    // Fallback to the directory containing the file
    return path.dirname(filePath);
  }

  private isContextFile(filePath: string): boolean {
    const fileName = path.basename(filePath);
    const uppercaseMdPattern = /^[A-Z][A-Z0-9_-]*\.md$/;
    
    return uppercaseMdPattern.test(fileName) && 
           !this.detector.isExcluded(fileName);
  }

  private isCommandFile(filePath: string): boolean {
    return filePath.includes('/.claude/commands/') && filePath.endsWith('.md');
  }

  private async runMarkdownLint(filePath: string): Promise<void> {
    try {
      // Use markdownlint-cli2 for better performance and configuration
      const command = `npx markdownlint-cli2 "${filePath}"`;
      
      execSync(command, { 
        stdio: ['pipe', 'pipe', 'pipe'],
        encoding: 'utf8'
      });
      
      // Don't log successful lint passes to reduce verbosity
    } catch (error) {
      // Markdown lint failures shouldn't stop the sync process
      // Only log if there are actual errors, not warnings
      // Silently continue for now to reduce noise
    }
  }

  /**
   * Syncs global workflows bidirectionally - latest version wins and propagates to all locations
   */
  async syncGlobalWorkflows(): Promise<SyncResult> {
    const detectionResult = await this.detector.detectGlobalWorkflowFiles();
    if (!detectionResult.success || !detectionResult.data) {
      return { filesProcessed: 0, filesUpdated: 0, success: false };
    }

    const allFiles = detectionResult.data;
    
    // Group files by name to compare across all three locations
    const filesByName = new Map<string, ContextFile[]>();
    
    for (const file of allFiles) {
      const fileName = path.basename(file.filePath);
      if (!filesByName.has(fileName)) {
        filesByName.set(fileName, []);
      }
      filesByName.get(fileName)!.push(file);
    }

    let filesProcessed = 0;
    let filesUpdated = 0;

    const updatedFiles: string[] = [];
    const skippedFiles: string[] = [];

    // Process each file group
    for (const [fileName, files] of filesByName) {
      filesProcessed++;
      
      // Find the most recently modified file across all locations
      let newestFile = files[0];
      for (const file of files) {
        if (file.lastModified > newestFile.lastModified) {
          newestFile = file;
        }
      }

      // Only sync if there are actually different versions
      if (files.length === 1) {
        skippedFiles.push(fileName);
        continue;
      }

      // Sync the newest version to all other locations
      const syncResults = await this.syncFileToAllLocations(newestFile, fileName);
      const syncCount = syncResults.filter(Boolean).length;
      
      if (syncCount > 0) {
        updatedFiles.push(fileName);
        filesUpdated += syncCount;
      } else {
        skippedFiles.push(fileName);
      }
    }

    // Summary output
    if (updatedFiles.length > 0) {
      console.error(`✓ Updated: ${updatedFiles.join(', ')}`);
    }
    if (skippedFiles.length > 0) {
      console.error(`→ Skipped: ${skippedFiles.length} files`);
    }

    return { filesProcessed, filesUpdated, success: true };
  }

  /**
   * Syncs a file to all three global workflow locations
   */
  private async syncFileToAllLocations(sourceFile: ContextFile, fileName: string): Promise<boolean[]> {
    const workflowPaths = require('../config/paths').getWorkflowPaths();
    const results: boolean[] = [];

    // Paths for all three locations
    const aiCommandPath = path.join(workflowPaths.source, fileName);
    const claudePath = path.join(workflowPaths.destinations.claude, fileName);
    const windsurfPath = path.join(workflowPaths.destinations.windsurf, fileName);

    // Sync to AI commands source (if not already the source)
    if (sourceFile.type !== 'ai-command') {
      const success = await this.syncToAiCommand(sourceFile, aiCommandPath);
      results.push(success);
    }

    // Sync to Claude commands (if not already the source)  
    if (sourceFile.type !== 'claude-global-command') {
      const success = await this.syncToClaudeCommand(sourceFile, claudePath);
      results.push(success);
    }

    // Sync to Windsurf workflows (if not already the source)
    if (sourceFile.type !== 'windsurf-global-workflow') {
      const success = await this.syncToWindsurfWorkflow(sourceFile, windsurfPath);
      results.push(success);
    }

    return results;
  }

  private async syncToAiCommand(sourceFile: ContextFile, targetPath: string): Promise<boolean> {
    const metadata = this.detector.createSyncMetadata(sourceFile.filePath);
    
    let mergeResult;
    if (sourceFile.type === 'claude-global-command') {
      mergeResult = this.contentMerger.mergeClaudeToAiCommand(sourceFile.content, metadata);
    } else if (sourceFile.type === 'windsurf-global-workflow') {
      mergeResult = this.contentMerger.mergeWindsurfToAiCommand(sourceFile.content, metadata);
    } else {
      return false; // Unknown source type
    }

    if (!mergeResult.success) return false;

    const writeResult = await this.fileOps.writeFile(targetPath, mergeResult.mergedContent);
    if (writeResult.success) {
      await this.runMarkdownLint(targetPath);
    }
    return writeResult.success;
  }

  private async syncToClaudeCommand(sourceFile: ContextFile, targetPath: string): Promise<boolean> {
    const metadata = this.detector.createSyncMetadata(sourceFile.filePath);
    
    let mergeResult;
    if (sourceFile.type === 'ai-command') {
      mergeResult = this.contentMerger.mergeAiCommandToClaude(sourceFile.content, metadata);
    } else if (sourceFile.type === 'windsurf-global-workflow') {
      mergeResult = this.contentMerger.mergeWindsurfToAiCommand(sourceFile.content, metadata);
    } else {
      return false; // Unknown source type
    }

    if (!mergeResult.success) return false;

    const writeResult = await this.fileOps.writeFile(targetPath, mergeResult.mergedContent);
    if (writeResult.success) {
      await this.runMarkdownLint(targetPath);
    }
    return writeResult.success;
  }

  private async syncToWindsurfWorkflow(sourceFile: ContextFile, targetPath: string): Promise<boolean> {
    const metadata = this.detector.createSyncMetadata(sourceFile.filePath);
    
    // Read existing Windsurf file to preserve frontmatter
    const existingContent = await this.fileOps.fileExists(targetPath)
      ? (await this.fileOps.readFile(targetPath)).data
      : undefined;

    let mergeResult;
    if (sourceFile.type === 'ai-command') {
      mergeResult = this.contentMerger.mergeAiCommandToWindsurf(sourceFile.content, metadata, existingContent);
    } else if (sourceFile.type === 'claude-global-command') {
      mergeResult = this.contentMerger.mergeClaudeToAiCommand(sourceFile.content, metadata);
      if (mergeResult.success) {
        // Convert the cleaned content to Windsurf format
        mergeResult = this.contentMerger.mergeAiCommandToWindsurf(mergeResult.mergedContent, metadata, existingContent);
      }
    } else {
      return false; // Unknown source type
    }

    if (!mergeResult.success) return false;

    const writeResult = await this.fileOps.writeFile(targetPath, mergeResult.mergedContent);
    if (writeResult.success) {
      await this.runMarkdownLint(targetPath);
    }
    return writeResult.success;
  }

  /**
   * Syncs a single global workflow file back to AI commands source
   */
  async syncGlobalWorkflowToSource(
    modifiedFilePath: string
  ): Promise<SyncResult> {
    // Determine the type of the modified file
    const contextFile = await this.createContextFileFromPath(modifiedFilePath);
    if (!contextFile) {
      return { filesProcessed: 0, filesUpdated: 0, success: false };
    }

    const fileName = path.basename(modifiedFilePath, '.md');
    let syncResult: boolean = false;

    if (contextFile.type === 'claude-global-command') {
      syncResult = await this.syncClaudeGlobalCommandToSource(contextFile);
    } else if (contextFile.type === 'windsurf-global-workflow') {
      syncResult = await this.syncWindsurfGlobalWorkflowToSource(contextFile);
    } else {
      return { filesProcessed: 0, filesUpdated: 0, success: true };
    }

    const filesUpdated = syncResult ? 1 : 0;
    console.error(`✓ Global workflow sync to source complete: ${filesUpdated}/1 files updated`);
    
    return { filesProcessed: 1, filesUpdated, success: true };
  }

  private async syncAiCommandToClaude(aiCommandFile: ContextFile): Promise<boolean> {
    const fileName = path.basename(aiCommandFile.filePath);
    const workflowPaths = require('../config/paths').getWorkflowPaths();
    const claudeFilePath = path.join(workflowPaths.destinations.claude, fileName);
    
    // Check if Claude file exists and compare timestamps
    const claudeExists = await this.fileOps.fileExists(claudeFilePath);
    if (claudeExists) {
      const claudeStatsResult = await this.fileOps.getFileStats(claudeFilePath);
      if (claudeStatsResult.success && claudeStatsResult.data) {
        const timeDiffMs = claudeStatsResult.data.mtime.getTime() - aiCommandFile.lastModified.getTime();
        if (timeDiffMs > 5000) {
          // Skip silently, handled in summary
          return false;
        }
      }
    }

    const metadata = this.detector.createSyncMetadata(aiCommandFile.filePath);
    const mergeResult = this.contentMerger.mergeAiCommandToClaude(
      aiCommandFile.content,
      metadata
    );

    if (!mergeResult.success) {
      return false;
    }

    const writeResult = await this.fileOps.writeFile(claudeFilePath, mergeResult.mergedContent);
    if (!writeResult.success) {
      return false;
    }

    console.error(`✓ Updated Claude global command: ${fileName}`);
    await this.runMarkdownLint(claudeFilePath);
    return true;
  }

  private async syncAiCommandToWindsurf(aiCommandFile: ContextFile): Promise<boolean> {
    const fileName = path.basename(aiCommandFile.filePath);
    const workflowPaths = require('../config/paths').getWorkflowPaths();
    const windsurfFilePath = path.join(workflowPaths.destinations.windsurf, fileName);
    
    // Check if Windsurf file exists and compare timestamps
    const windsurfExists = await this.fileOps.fileExists(windsurfFilePath);
    if (windsurfExists) {
      const windsurfStatsResult = await this.fileOps.getFileStats(windsurfFilePath);
      if (windsurfStatsResult.success && windsurfStatsResult.data) {
        const timeDiffMs = windsurfStatsResult.data.mtime.getTime() - aiCommandFile.lastModified.getTime();
        if (timeDiffMs > 5000) {
          // Skip silently, handled in summary
          return false;
        }
      }
    }

    // Read existing Windsurf file to preserve frontmatter
    const existingWindsurfContent = windsurfExists
      ? (await this.fileOps.readFile(windsurfFilePath)).data
      : undefined;

    const metadata = this.detector.createSyncMetadata(aiCommandFile.filePath);
    const mergeResult = this.contentMerger.mergeAiCommandToWindsurf(
      aiCommandFile.content,
      metadata,
      existingWindsurfContent
    );

    if (!mergeResult.success) {
      return false;
    }

    const writeResult = await this.fileOps.writeFile(windsurfFilePath, mergeResult.mergedContent);
    if (!writeResult.success) {
      return false;
    }

    console.error(`✓ Updated Windsurf global workflow: ${fileName}`);
    await this.runMarkdownLint(windsurfFilePath);
    return true;
  }

  private async syncClaudeGlobalCommandToSource(claudeFile: ContextFile): Promise<boolean> {
    const fileName = path.basename(claudeFile.filePath);
    const workflowPaths = require('../config/paths').getWorkflowPaths();
    const sourceFilePath = path.join(workflowPaths.source, fileName);
    
    // Check if source file exists and compare timestamps
    const sourceExists = await this.fileOps.fileExists(sourceFilePath);
    if (sourceExists) {
      const sourceStatsResult = await this.fileOps.getFileStats(sourceFilePath);
      if (sourceStatsResult.success && sourceStatsResult.data) {
        const timeDiffMs = sourceStatsResult.data.mtime.getTime() - claudeFile.lastModified.getTime();
        if (timeDiffMs > 5000) {
          // Skip silently, handled in summary
          return false;
        }
      }
    }

    const metadata = this.detector.createSyncMetadata(claudeFile.filePath);
    const mergeResult = this.contentMerger.mergeClaudeToAiCommand(
      claudeFile.content,
      metadata
    );

    if (!mergeResult.success) {
      return false;
    }

    const writeResult = await this.fileOps.writeFile(sourceFilePath, mergeResult.mergedContent);
    if (!writeResult.success) {
      return false;
    }

    console.error(`✓ Updated AI command source: ${fileName}`);
    await this.runMarkdownLint(sourceFilePath);
    return true;
  }

  private async syncWindsurfGlobalWorkflowToSource(windsurfFile: ContextFile): Promise<boolean> {
    const fileName = path.basename(windsurfFile.filePath);
    const workflowPaths = require('../config/paths').getWorkflowPaths();
    const sourceFilePath = path.join(workflowPaths.source, fileName);
    
    // Check if source file exists and compare timestamps
    const sourceExists = await this.fileOps.fileExists(sourceFilePath);
    if (sourceExists) {
      const sourceStatsResult = await this.fileOps.getFileStats(sourceFilePath);
      if (sourceStatsResult.success && sourceStatsResult.data) {
        const timeDiffMs = sourceStatsResult.data.mtime.getTime() - windsurfFile.lastModified.getTime();
        if (timeDiffMs > 5000) {
          // Skip silently, handled in summary
          return false;
        }
      }
    }

    const metadata = this.detector.createSyncMetadata(windsurfFile.filePath);
    const mergeResult = this.contentMerger.mergeWindsurfToAiCommand(
      windsurfFile.content,
      metadata
    );

    if (!mergeResult.success) {
      return false;
    }

    const writeResult = await this.fileOps.writeFile(sourceFilePath, mergeResult.mergedContent);
    if (!writeResult.success) {
      return false;
    }

    console.error(`✓ Updated AI command source: ${fileName}`);
    await this.runMarkdownLint(sourceFilePath);
    return true;
  }

  private async createContextFileFromPath(filePath: string): Promise<ContextFile | null> {
    const contentResult = await this.fileOps.readFile(filePath);
    if (!contentResult.success) {
      return null;
    }

    const statsResult = await this.fileOps.getFileStats(filePath);
    if (!statsResult.success || !statsResult.data) {
      return null;
    }

    const content = contentResult.data || '';
    const type = this.detector['determineFileType'](filePath); // Access private method
    const syncMetadata = this.detector.extractSyncMetadata(content);

    return {
      content,
      filePath,
      lastModified: statsResult.data.mtime,
      syncMetadata,
      type
    };
  }
}