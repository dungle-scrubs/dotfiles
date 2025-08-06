import * as path from 'path';
import type { 
  ContextFile, 
  ContextFileType, 
  FileOperationResult,
  SyncMetadata 
} from '../types/sync';
import { EXCLUDED_FILES, SYNC_VERSION } from '../types/sync';
import { FileOperations } from '../utils/file-operations';
import { getWorkflowPaths, getExpandedProjectFilePaths } from '../config/paths';

export class ContextFileDetector {
  constructor(
    private readonly fileOps: FileOperations,
    private readonly excludedFiles: readonly string[] = EXCLUDED_FILES
  ) {}

  async detectContextFiles(projectRoot: string): Promise<FileOperationResult<ContextFile[]>> {
    try {
      const contextFiles: ContextFile[] = [];

      // Find uppercase MD files (traditional context files)
      const uppercaseMdPattern = /^[A-Z][A-Z0-9_-]*\.md$/;
      const uppercaseResult = await this.fileOps.findFiles(projectRoot, uppercaseMdPattern);
      
      if (uppercaseResult.success && uppercaseResult.data) {
        for (const filePath of uppercaseResult.data) {
          const fileName = path.basename(filePath);
          
          if (this.isExcludedFile(fileName)) {
            continue;
          }

          const contextFile = await this.createContextFile(filePath);
          if (contextFile) {
            contextFiles.push(contextFile);
          }
        }
      }

      // Get project file paths from centralized config
      const projectPaths = getExpandedProjectFilePaths(projectRoot);
      
      // Find command files in .claude/commands/ directories
      const commandPattern = /\.md$/;
      const commandResult = await this.fileOps.findFiles(projectPaths.claudeCommands, commandPattern);
      
      if (commandResult.success && commandResult.data) {
        for (const filePath of commandResult.data) {
          const contextFile = await this.createContextFile(filePath);
          if (contextFile) {
            contextFiles.push(contextFile);
          }
        }
      }

      // Find workflow files in .windsurf/workflows/ directories
      const workflowPattern = /\.md$/;
      const workflowResult = await this.fileOps.findFiles(projectPaths.windsurfWorkflows, workflowPattern);
      
      if (workflowResult.success && workflowResult.data) {
        for (const filePath of workflowResult.data) {
          const contextFile = await this.createContextFile(filePath);
          if (contextFile) {
            contextFiles.push(contextFile);
          }
        }
      }

      return { data: contextFiles, success: true };
    } catch (error) {
      return {
        error: error instanceof Error ? error : new Error('Unknown detection error'),
        success: false
      };
    }
  }

  private async createContextFile(filePath: string): Promise<ContextFile | null> {
    const contentResult = await this.fileOps.readFile(filePath);
    if (!contentResult.success) {
      return null;
    }

    // Handle empty files
    const content = contentResult.data || '';
    const trimmedContent = content.trim();
    
    if (trimmedContent === '') {
      return null;
    }

    const statsResult = await this.fileOps.getFileStats(filePath);
    if (!statsResult.success || !statsResult.data) {
      return null;
    }

    const fileName = path.basename(filePath);
    const type = this.determineFileType(filePath);
    const syncMetadata = this.extractSyncMetadata(content);

    return {
      content,
      filePath,
      lastModified: statsResult.data.mtime,
      syncMetadata,
      type
    };
  }

  private determineFileType(filePath: string): ContextFileType {
    const fileName = path.basename(filePath);
    const workflowPaths = getWorkflowPaths();
    
    if (fileName === 'CLAUDE.md') {
      return 'claude';
    }
    
    // Check if file is in Windsurf rules directory or named WINDSURF.md
    if (fileName === 'WINDSURF.md' || filePath.includes('/.windsurf/rules/')) {
      return 'windsurf';
    }
    
    // Check if file is in AI commands source directory
    if (filePath.startsWith(workflowPaths.source)) {
      return 'ai-command';
    }
    
    // Check if file is in Claude global commands directory
    if (filePath.startsWith(workflowPaths.destinations.claude)) {
      return 'claude-global-command';
    }
    
    // Check if file is in Windsurf global workflows directory
    if (filePath.startsWith(workflowPaths.destinations.windsurf)) {
      return 'windsurf-global-workflow';
    }
    
    // Check if file is in Claude commands directory (project-level)
    if (filePath.includes('/.claude/commands/')) {
      return 'claude-command';
    }
    
    // Check if file is in Windsurf workflows directory (project-level)
    if (filePath.includes('/.windsurf/workflows/')) {
      return 'windsurf-workflow';
    }
    
    return 'other';
  }

  extractSyncMetadata(content: string): SyncMetadata | undefined {
    const syncMetadataRegex = /<!-- Last synced: (.+?) -->\s*<!-- Source: (.+?) -->\s*<!-- Sync version: (.+?) -->/;
    const match = content.match(syncMetadataRegex);
    
    if (!match) {
      return undefined;
    }

    return {
      lastSyncTime: new Date(match[1]),
      sourceFile: match[2].trim(),
      syncVersion: match[3].trim()
    };
  }

  private isExcludedFile(fileName: string): boolean {
    return this.excludedFiles.includes(fileName as any);
  }

  isExcluded(fileName: string): boolean {
    return this.isExcludedFile(fileName);
  }

  createSyncMetadata(sourceFile: string): SyncMetadata {
    return {
      lastSyncTime: new Date(),
      sourceFile,
      syncVersion: SYNC_VERSION
    };
  }

  formatSyncMetadata(metadata: SyncMetadata): string {
    return `<!-- Last synced: ${metadata.lastSyncTime.toISOString()} -->
<!-- Source: ${metadata.sourceFile} -->
<!-- Sync version: ${metadata.syncVersion} -->`;
  }

  /**
   * Detects global workflow files from all three locations:
   * - AI commands source directory
   * - Claude global commands directory  
   * - Windsurf global workflows directory
   */
  async detectGlobalWorkflowFiles(): Promise<FileOperationResult<ContextFile[]>> {
    try {
      const contextFiles: ContextFile[] = [];
      const workflowPaths = getWorkflowPaths();
      const workflowPattern = /\.md$/;

      // Find files in AI commands source directory
      const sourceResult = await this.fileOps.findFiles(workflowPaths.source, workflowPattern);
      if (sourceResult.success && sourceResult.data) {
        for (const filePath of sourceResult.data) {
          const contextFile = await this.createContextFile(filePath);
          if (contextFile) {
            contextFiles.push(contextFile);
          }
        }
      }

      // Find files in Claude global commands directory
      const claudeResult = await this.fileOps.findFiles(workflowPaths.destinations.claude, workflowPattern);
      if (claudeResult.success && claudeResult.data) {
        for (const filePath of claudeResult.data) {
          const contextFile = await this.createContextFile(filePath);
          if (contextFile) {
            contextFiles.push(contextFile);
          }
        }
      }

      // Find files in Windsurf global workflows directory
      const windsurfResult = await this.fileOps.findFiles(workflowPaths.destinations.windsurf, workflowPattern);
      if (windsurfResult.success && windsurfResult.data) {
        for (const filePath of windsurfResult.data) {
          const contextFile = await this.createContextFile(filePath);
          if (contextFile) {
            contextFiles.push(contextFile);
          }
        }
      }

      return { data: contextFiles, success: true };
    } catch (error) {
      return {
        error: error instanceof Error ? error : new Error('Unknown global workflow detection error'),
        success: false
      };
    }
  }
}