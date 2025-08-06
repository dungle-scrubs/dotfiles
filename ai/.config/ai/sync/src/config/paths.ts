import * as path from "path";

export interface GlobalConfigPaths {
	readonly source: string;
	readonly destinations: {
		readonly claude: string;
		readonly windsurf: string;
	};
}

export interface WorkflowPaths {
	readonly source: string;
	readonly destinations: {
		readonly claude: string;
		readonly windsurf: string;
	};
}

export interface ProjectFilePaths {
	readonly claudeCommands: string;
	readonly windsurfRules: string;
	readonly windsurfWorkflows: string;
}

export interface PathConfig {
	readonly globalConfig: GlobalConfigPaths;
	readonly workflows: WorkflowPaths;
	readonly projectFiles: ProjectFilePaths;
}

/**
 * Expands tilde (~) to the user's home directory
 */
function expandPath(filePath: string): string {
	return filePath.replace(/^~/, process.env.HOME || "");
}

/**
 * Centralized path configuration for all sync operations
 */
export const PATH_CONFIG: PathConfig = {
	globalConfig: {
		source: "~/.config/ai/global",
		destinations: {
			claude: "~/dotfiles/claude/.claude/CLAUDE.md",
			windsurf: "~/dotfiles/codeium/.codeium/windsurf/memories/global_rules.md",
		},
	},
	workflows: {
		source: "~/dotfiles/ai/.config/ai/commands",
		destinations: {
			claude: "~/dotfiles/claude/.claude/commands",
			windsurf: "~/dotfiles/codeium/.codeium/windsurf/global_workflows",
		},
	},
	projectFiles: {
		claudeCommands: ".claude/commands",
		windsurfRules: ".windsurf/rules",
		windsurfWorkflows: ".windsurf/workflows",
	},
} as const;

/**
 * Returns expanded paths for global configuration
 */
export function getGlobalConfigPaths(): GlobalConfigPaths {
	return {
		source: expandPath(PATH_CONFIG.globalConfig.source),
		destinations: {
			claude: expandPath(PATH_CONFIG.globalConfig.destinations.claude),
			windsurf: expandPath(PATH_CONFIG.globalConfig.destinations.windsurf),
		},
	};
}

/**
 * Returns expanded paths for workflows
 */
export function getWorkflowPaths(): WorkflowPaths {
	return {
		source: expandPath(PATH_CONFIG.workflows.source),
		destinations: {
			claude: expandPath(PATH_CONFIG.workflows.destinations.claude),
			windsurf: expandPath(PATH_CONFIG.workflows.destinations.windsurf),
		},
	};
}

/**
 * Returns project file paths (relative to project root)
 */
export function getProjectFilePaths(): ProjectFilePaths {
	return PATH_CONFIG.projectFiles;
}

/**
 * Returns expanded project file paths for a given project root
 */
export function getExpandedProjectFilePaths(
	projectRoot: string,
): ProjectFilePaths {
	return {
		claudeCommands: path.join(
			projectRoot,
			PATH_CONFIG.projectFiles.claudeCommands,
		),
		windsurfRules: path.join(
			projectRoot,
			PATH_CONFIG.projectFiles.windsurfRules,
		),
		windsurfWorkflows: path.join(
			projectRoot,
			PATH_CONFIG.projectFiles.windsurfWorkflows,
		),
	};
}
