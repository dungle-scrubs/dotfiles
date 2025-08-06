#!/usr/bin/env node

import { ContentMerger } from './services/content-merger';
import { ContextFileDetector } from './services/context-file-detector';
import { SyncOrchestrator } from './services/sync-orchestrator';
import { FileOperations } from './utils/file-operations';

async function main(): Promise<void> {
  process.stderr.write('\n'); // Start with empty line before markup
  
  // Get project directory from command line argument
  const projectRoot = process.argv[2] || process.cwd();
  console.error(`Windsurf → Claude sync starting in: ${projectRoot}`);

  const fileOps = new FileOperations();
  const detector = new ContextFileDetector(fileOps);
  const merger = new ContentMerger();
  const orchestrator = new SyncOrchestrator(merger, detector, fileOps);

  const result = await orchestrator.syncWindsurfToClaude(projectRoot);
  
  if (!result.success) {
    console.error('✗ Sync failed');
    process.stderr.write('\n'); // End with empty line after markup
    process.exit(1);
  }

  if (result.filesUpdated === 0) {
    console.error('→ No files needed updating');
  }
  
  process.stderr.write('\n'); // End with empty line after markup
}

// Export main function for use by wrapper script
export { main };

// Run the script when called directly or required
if (require.main === module || process.argv[1]?.includes('windsurf-to-claude')) {
  main().catch((error) => {
    console.error('✗ Fatal error:', error);
    process.exit(1);
  });
}