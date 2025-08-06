export interface ContextFile {
	readonly content: string;
	readonly filePath: string;
	readonly lastModified: Date;
	readonly syncMetadata?: SyncMetadata;
	readonly type: ContextFileType;
}

export interface ContentMergeResult {
	readonly mergedContent: string;
	readonly success: boolean;
}

export interface FileOperationResult<TData = void> {
	readonly data?: TData;
	readonly error?: Error;
	readonly success: boolean;
}

export interface SyncMetadata {
	readonly lastSyncTime: Date;
	readonly sourceFile: string;
	readonly syncVersion: string;
}

export interface SyncResult {
	readonly filesProcessed: number;
	readonly filesUpdated: number;
	readonly success: boolean;
}

export type ContextFileType = "claude" | "windsurf" | "claude-command" | "windsurf-workflow" | "ai-command" | "claude-global-command" | "windsurf-global-workflow" | "other";

export const EXCLUDED_FILES = [
	"ACKNOWLEDGMENTS.md",
	"AUTHORS.md",
	"CHANGELOG.md",
	"DEPLOY_CHANGELOG.md",
	"CODE_OF_CONDUCT.md",
	"CONTRIBUTING.md",
	"CREDITS.md",
	"FAQ.md",
	"HISTORY.md",
	"INSTALL.md",
	"LICENSE.md",
	"LOGS.md",
	"NODE-LICENSE.md",
	"NOTES.md",
	"README.md",
	"SECURITY.md",
	"SUPPORT.md",
	"TODO.md",
	"TROUBLESHOOTING.md",
	"UPGRADE.md",
] as const;

export const SYNC_VERSION = "1.0.0" as const;

export type WindsurfTriggerType = 'manual' | 'model_decision' | 'always_off' | 'always_on' | 'glob';

export const DEFAULT_WINDSURF_TRIGGER: WindsurfTriggerType = 'model_decision' as const;

export interface WindsurfRuleFrontmatter {
	readonly description?: string; // For non-glob triggers
	readonly globs?: string;       // For glob trigger only - "files matching the glob pattern"
	readonly trigger: WindsurfTriggerType;
}

export interface WindsurfWorkflowFrontmatter {
	readonly description: string; // Required for workflows
}

export type WindsurfFrontmatter = WindsurfRuleFrontmatter | WindsurfWorkflowFrontmatter;

export function isWorkflowFrontmatter(frontmatter: WindsurfFrontmatter): frontmatter is WindsurfWorkflowFrontmatter {
	return 'trigger' in frontmatter === false;
}

export function isRuleFrontmatter(frontmatter: WindsurfFrontmatter): frontmatter is WindsurfRuleFrontmatter {
	return 'trigger' in frontmatter;
}
