#!/usr/bin/env node

import * as path from 'path';
import { execSync } from 'child_process';
import { ContentMerger } from './services/content-merger';
import { ContextFileDetector } from './services/context-file-detector';
import { SyncOrchestrator } from './services/sync-orchestrator';
import { FileOperations } from './utils/file-operations';

async function main(): Promise<void> {
  // Try to get file path from arguments first, then environment variables
  let modifiedFilePath = process.argv[2];
  let projectRoot = process.argv[3];
  
  // Debug: Show all arguments and environment variables
  console.error(`Debug - Args: [${process.argv.slice(2).join(', ')}]`);
  console.error(`Debug - Env vars: filePath=${process.env.filePath}, FILE_PATH=${process.env.FILE_PATH}, ORIGINAL_PWD=${process.env.ORIGINAL_PWD}, PWD=${process.env.PWD}`);
  console.error(`Debug - All env vars with 'file' or 'path':`, Object.keys(process.env).filter(k => k.toLowerCase().includes('file') || k.toLowerCase().includes('path')).map(k => `${k}=${process.env[k]}`));
  
  // If no file path in args, try environment variables
  if (!modifiedFilePath || modifiedFilePath.trim() === '') {
    modifiedFilePath = process.env.filePath || process.env.FILE_PATH || process.env.MODIFIED_FILE || '';
  }
  
  // If no project root in args, use ORIGINAL_PWD first, then PWD
  if (!projectRoot || projectRoot.trim() === '') {
    projectRoot = process.env.ORIGINAL_PWD || process.env.PWD || process.cwd();
  }
  
  if (!modifiedFilePath || modifiedFilePath.trim() === '') {
    console.error('✗ No file path provided');
    console.error('Usage: claude-to-windsurf.ts <file-path> <project-root>');
    console.error('Or set filePath/FILE_PATH environment variable');
    process.exit(1);
  }

  if (!projectRoot || projectRoot.trim() === '') {
    console.error('✗ No project directory provided');
    console.error('Usage: claude-to-windsurf.ts <file-path> <project-root>');
    process.exit(1);
  }

  // Convert relative path to absolute
  const absoluteFilePath = path.resolve(projectRoot, modifiedFilePath);
  
  console.error(`Claude → Windsurf sync for: ${path.basename(absoluteFilePath)}`);

  const fileOps = new FileOperations();
  const detector = new ContextFileDetector(fileOps);
  const merger = new ContentMerger();
  const orchestrator = new SyncOrchestrator(merger, detector, fileOps);

  const result = await orchestrator.syncClaudeToWindsurf(
    absoluteFilePath, 
    projectRoot
  );
  
  if (!result.success) {
    console.error('✗ Sync failed');
    process.exit(1);
  }

  if (result.filesUpdated === 0) {
    console.error('→ No sync needed');
  }
}

// Export main function for use by wrapper script
export { main };

// Run the script when called directly or required
if (require.main === module || process.argv[1]?.includes('claude-to-windsurf')) {
  main().catch((error) => {
    console.error('✗ Fatal error:', error);
    process.exit(1);
  });
}