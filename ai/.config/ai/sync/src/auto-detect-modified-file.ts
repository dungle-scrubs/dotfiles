#!/usr/bin/env node

import * as fs from 'fs';
import * as path from 'path';

function findRecentlyModifiedFiles(projectRoot: string, maxAgeSeconds: number = 10): string[] {
  const now = Date.now();
  const maxAge = maxAgeSeconds * 1000;
  const recentFiles: Array<{path: string, mtime: number}> = [];

  function scanDirectory(dir: string) {
    try {
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        
        // Skip hidden directories and node_modules
        if (entry.isDirectory()) {
          if (!entry.name.startsWith('.') && entry.name !== 'node_modules') {
            scanDirectory(fullPath);
          }
        } else if (entry.isFile() && entry.name.endsWith('.md')) {
          try {
            const stats = fs.statSync(fullPath);
            const ageMs = now - stats.mtime.getTime();
            
            if (ageMs <= maxAge) {
              recentFiles.push({
                path: fullPath,
                mtime: stats.mtime.getTime()
              });
            }
          } catch (err) {
            // Skip files we can't stat
          }
        }
      }
    } catch (err) {
      // Skip directories we can't read
    }
  }

  scanDirectory(projectRoot);
  
  // Sort by modification time (newest first)
  return recentFiles
    .sort((a, b) => b.mtime - a.mtime)
    .map(f => f.path);
}

function isContextOrCommandFile(filePath: string): boolean {
  const fileName = path.basename(filePath);
  const uppercaseMdPattern = /^[A-Z][A-Z0-9_-]*\.md$/;
  
  // Check if it's an uppercase MD file (context file)
  if (uppercaseMdPattern.test(fileName)) {
    return true;
  }
  
  // Check if it's in a commands directory
  if (filePath.includes('/.claude/commands/') && filePath.endsWith('.md')) {
    return true;
  }
  
  return false;
}

function main() {
  const projectRoot = process.argv[2] || process.cwd();
  console.error(`Scanning for recently modified files in: ${projectRoot}`);
  
  const recentFiles = findRecentlyModifiedFiles(projectRoot, 10);
  const contextFiles = recentFiles.filter(isContextOrCommandFile);
  
  console.error(`Found ${recentFiles.length} recently modified .md files`);
  console.error(`Found ${contextFiles.length} recently modified context/command files`);
  
  if (contextFiles.length > 0) {
    const mostRecent = contextFiles[0];
    console.error(`Most recent context/command file: ${path.basename(mostRecent)}`);
    console.log(mostRecent); // Output the file path for the calling script
  } else {
    console.error('No recently modified context/command files found');
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}