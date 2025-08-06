#!/usr/bin/env node

import * as path from "path";
import { execSync } from "child_process";

interface ToolResponse {
	filePath?: string;
	success?: boolean;
}

interface ToolInput {
	file_path?: string;
	content?: string;
}

interface PostToolUseData {
	tool_name: string;
	tool_input: ToolInput;
	tool_response: ToolResponse;
}

async function main(): Promise<void> {
	// Get the original project directory before changing to sync directory
	const originalPwd = process.cwd();

	console.error(`PostToolUse wrapper starting in: ${originalPwd}`);

	// Read JSON data from stdin
	let hookData: PostToolUseData;
	try {
		const stdinData = process.argv[2]; // Hook data might be passed as argument
		if (stdinData) {
			hookData = JSON.parse(stdinData);
		} else {
			// Try reading from stdin
			const chunks: Buffer[] = [];
			for await (const chunk of process.stdin) {
				chunks.push(chunk);
			}
			const rawData = Buffer.concat(chunks).toString();
			hookData = JSON.parse(rawData);
		}
	} catch (error) {
		console.error("✗ Failed to parse hook data:", error);
		console.error("Args:", process.argv);
		process.exit(1);
	}

	console.error(`Tool: ${hookData.tool_name}`);
	console.error(`Tool response filePath: ${hookData.tool_response?.filePath}`);
	console.error(`Tool input file_path: ${hookData.tool_input?.file_path}`);

	// Get the file path from tool_response.filePath or tool_input.file_path
	const filePath =
		hookData.tool_response?.filePath || hookData.tool_input?.file_path;

	if (!filePath) {
		console.error("✗ No file path found in hook data");
		process.exit(1);
	}

	// Check if this is a file we should sync
	const fileName = path.basename(filePath);
	const uppercaseMdPattern = /^[A-Z][A-Z0-9_-]*\.md$/;
	const isContextFile = uppercaseMdPattern.test(fileName);
	const isCommandFile =
		filePath.includes("/.claude/commands/") && filePath.endsWith(".md");

	if (!isContextFile && !isCommandFile) {
		console.error(`→ Skipping ${fileName}: Not a context or command file`);
		process.exit(0);
	}

	console.error(
		`→ Syncing ${fileName} (${isCommandFile ? "command" : "context"} file)`,
	);

	// Run the sync
	try {
		const result = execSync(
			`cd ~/.config/ai/sync && pnpm dlx tsx src/claude-to-windsurf.ts "${filePath}" "${originalPwd}"`,
			{ encoding: "utf8", stdio: "inherit" },
		);
		console.error("✓ Sync completed successfully");
	} catch (error) {
		console.error("✗ Sync failed:", error);
		process.exit(1);
	}
}

if (require.main === module) {
	main().catch((error) => {
		console.error("✗ Fatal error:", error);
		process.exit(1);
	});
}
