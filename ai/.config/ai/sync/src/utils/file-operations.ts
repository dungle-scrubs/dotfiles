import * as fs from 'fs-extra';
import * as path from 'path';
import type { FileOperationResult } from '../types/sync';

export class FileOperations {
  async readFile(filePath: string): Promise<FileOperationResult<string>> {
    try {
      const content = await fs.readFile(filePath, 'utf-8');
      
      // If file appears empty but file system says it has size, retry once
      if (content === '' || content.trim() === '') {
        const stats = await fs.stat(filePath);
        if (stats.size > 0) {
          await new Promise(resolve => setTimeout(resolve, 100)); // 100ms delay
          const retryContent = await fs.readFile(filePath, 'utf-8');
          return { data: retryContent, success: true };
        }
      }
      
      return { data: content, success: true };
    } catch (error) {
      return { 
        error: error instanceof Error ? error : new Error('Unknown read error'),
        success: false 
      };
    }
  }

  async writeFile(filePath: string, content: string): Promise<FileOperationResult> {
    try {
      await fs.ensureDir(path.dirname(filePath));
      await fs.writeFile(filePath, content, 'utf-8');
      return { success: true };
    } catch (error) {
      return {
        error: error instanceof Error ? error : new Error('Unknown write error'),
        success: false
      };
    }
  }

  async getFileStats(filePath: string): Promise<FileOperationResult<fs.Stats>> {
    try {
      const stats = await fs.stat(filePath);
      return { data: stats, success: true };
    } catch (error) {
      return {
        error: error instanceof Error ? error : new Error('Unknown stat error'),
        success: false
      };
    }
  }

  async findFiles(
    directory: string, 
    pattern: RegExp
  ): Promise<FileOperationResult<string[]>> {
    try {
      const allFiles: string[] = [];
      const excludedDirs = new Set([
        'node_modules',
        '.git',
        '.next',
        '.nuxt',
        'dist',
        'build',
        '.cache',
        'coverage',
        '.nyc_output',
        'tmp',
        'temp'
      ]);
      
      const scanDirectory = async (dir: string): Promise<void> => {
        const entries = await fs.readdir(dir, { withFileTypes: true });
        
        for (const entry of entries) {
          const fullPath = path.join(dir, entry.name);
          
          if (entry.isDirectory()) {
            // Skip excluded directories
            if (!excludedDirs.has(entry.name)) {
              await scanDirectory(fullPath);
            }
          } else if (entry.isFile() && pattern.test(entry.name)) {
            allFiles.push(fullPath);
          }
        }
      };

      await scanDirectory(directory);
      return { data: allFiles, success: true };
    } catch (error) {
      return {
        error: error instanceof Error ? error : new Error('Unknown find error'),
        success: false
      };
    }
  }

  async fileExists(filePath: string): Promise<boolean> {
    try {
      await fs.access(filePath);
      return true;
    } catch {
      return false;
    }
  }
}