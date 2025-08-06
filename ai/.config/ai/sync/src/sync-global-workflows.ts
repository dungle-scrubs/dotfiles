#!/usr/bin/env node

import { ContentMerger } from './services/content-merger';
import { ContextFileDetector } from './services/context-file-detector';
import { SyncOrchestrator } from './services/sync-orchestrator';
import { FileOperations } from './utils/file-operations';

async function main(): Promise<void> {
  process.stderr.write('\n'); // Start with empty line before markup
  console.error('Global workflow synchronization starting...');

  const fileOps = new FileOperations();
  const detector = new ContextFileDetector(fileOps);
  const merger = new ContentMerger();
  const orchestrator = new SyncOrchestrator(merger, detector, fileOps);

  // Check if this is a reverse sync (from Claude/Windsurf back to source)
  const modifiedFilePath = process.argv[2];
  
  if (modifiedFilePath) {
    // Reverse sync: single file from Claude/Windsurf → AI commands source
    console.error(`Syncing modified global workflow back to source: ${modifiedFilePath}`);
    
    const syncResult = await orchestrator.syncGlobalWorkflowToSource(modifiedFilePath);
    
    if (!syncResult.success) {
      console.error('✗ Global workflow reverse sync failed');
      process.exit(1);
    } else if (syncResult.filesUpdated === 0) {
      console.error('→ No reverse sync needed');
    }
    
    console.error('✓ Global workflow reverse sync complete');
  } else {
    // Forward sync: AI commands source → Claude/Windsurf
    console.error('Syncing global workflows from source to destinations...');
    
    const syncResult = await orchestrator.syncGlobalWorkflows();
    
    if (!syncResult.success) {
      console.error('✗ Global workflow sync failed');
      process.exit(1);
    } else if (syncResult.filesUpdated === 0) {
      console.error('→ No global workflow files needed updating');
    }
    
    console.error('✓ Global workflow sync complete');
  }

  process.stderr.write('\n'); // End with empty line after markup
}

// Export main function for testing
export { main };

// Run the script when called directly
if (require.main === module || process.argv[1]?.includes('sync-global-workflows')) {
  main().catch((error) => {
    console.error('✗ Fatal error:', error);
    process.exit(1);
  });
}