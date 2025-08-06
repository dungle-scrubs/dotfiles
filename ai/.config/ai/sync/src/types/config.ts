export interface FileType {
  extension: string;
  priority: number;
}

export interface ProcessedFile {
  path: string;
  filename: string;
  extension: string;
  content: string;
  priority: number;
}

export interface ConfigLoader {
  globalConfigPath: string;
  supportedTypes: FileType[];
}

export const FILE_TYPES: FileType[] = [
  { extension: '.json', priority: 1 },
  { extension: '.toml', priority: 2 },
  { extension: '.md', priority: 3 }
];

export const DEFAULT_GLOBAL_CONFIG_PATH = '~/.config/ai/global';