#!/usr/bin/env node

import { GlobalContextBuilder } from './services/global-context-builder';
import { ContentMerger } from './services/content-merger';
import { ContextFileDetector } from './services/context-file-detector';
import { SyncOrchestrator } from './services/sync-orchestrator';
import { FileOperations } from './utils/file-operations';

async function main(): Promise<void> {
  process.stderr.write('\n'); // Start with empty line before markup
  
  console.error('\x1b[36mClaude session starting...\x1b[0m');

  // 1. Build global context files from components
  console.error('\x1b[36mBuilding global context files...\x1b[0m');
  const globalBuilder = new GlobalContextBuilder();
  const buildResult = await globalBuilder.buildGlobalContextFiles();
  
  if (!buildResult.success) {
    console.error('✗ Failed to build global context files');
    console.error(`  ${buildResult.error?.message || 'Unknown error'}`);
  } else {
    console.error(`✓ Built ${buildResult.data || 0} global context files`);
  }
  process.stderr.write('\n'); // Space between tasks

  // 2. Sync global workflows (bidirectional)
  console.error('\x1b[36mSyncing global workflows...\x1b[0m');
  const fileOps = new FileOperations();
  const detector = new ContextFileDetector(fileOps);
  const merger = new ContentMerger();
  const orchestrator = new SyncOrchestrator(merger, detector, fileOps);

  const globalWorkflowResult = await orchestrator.syncGlobalWorkflows();
  
  if (!globalWorkflowResult.success) {
    console.error('✗ Global workflow sync failed');
  } else if (globalWorkflowResult.filesUpdated === 0) {
    console.error('→ No changes needed');
  }
  process.stderr.write('\n'); // Space between tasks

  // 3. Run project-level sync (Windsurf → Claude)
  console.error('\x1b[36mSyncing project context files...\x1b[0m');
  const projectRoot = process.argv[2] || process.cwd();

  const syncResult = await orchestrator.syncWindsurfToClaude(projectRoot);
  
  if (!syncResult.success) {
    console.error('✗ Project sync failed');
  } else if (syncResult.filesUpdated === 0) {
    console.error('→ No changes needed');
  }

  console.error('\n✓ \x1b[32mSession initialization complete\x1b[0m');
  process.stderr.write('\n'); // End with empty line after session hook
}

// Export main function for use by wrapper script
export { main };

// Run the script when called directly or required
if (require.main === module || process.argv[1]?.includes('claude-session-start')) {
  main().catch((error) => {
    console.error('✗ Fatal error:', error);
    process.exit(1);
  });
}