---
trigger: model_decision
description: 🤖 AI: Please add a clear description of when this rule should apply
---

<!-- Last synced: 2025-08-06T03:07:56.748Z -->
<!-- Source: /Users/kevin/dotfiles/ai/.config/ai/sync/CLAUDE.md -->
<!-- Sync version: 1.0.0 -->

## CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
## AI Bootstrap - Context Synchronization System

This project provides seamless bidirectional synchronization between Claude Code and Windsurf IDE context files, ensuring consistent AI assistance across both development environments.
## Development Commands

```bash
## Install dependencies

pnpm install
## Run main session start script

pnpm start
## or

pnpm dev
## Execute individual sync operations directly

pnpm dlx tsx src/claude-session-start.ts
pnpm dlx tsx src/windsurf-to-claude.ts "/path/to/project"
pnpm dlx tsx src/claude-to-windsurf.ts "modified-file.md" "/path/to/project"
```
## Testing Hook Scripts

```bash
## Test global configuration loading

cd ~/dotfiles/ai/.config/ai/sync && pnpm dlx tsx src/claude-session-start.ts
## Test Windsurf → Claude sync

cd ~/dotfiles/ai/.config/ai/sync && pnpm dlx tsx src/windsurf-to-claude.ts
## Test Claude → Windsurf export

cd ~/dotfiles/ai/.config/ai/sync && pnpm dlx tsx src/claude-to-windsurf.ts CLAUDE.md
```
## Overview

The **ai-bootstrap** system automatically syncs context between:

* **CLAUDE.md** files (Claude Code context)
* **WINDSURF.md** files (Windsurf IDE context)
* Any other uppercase **.md** files (excluding documentation like README, CHANGELOG)

The synchronization is **Claude-centric** - Claude Code handles all sync operations while Windsurf passively receives updates.
## How It Works


## Session Startup (Windsurf → Claude)

When you start a Claude Code session, the **SessionStart** hook:

1. Scans the project for **WINDSURF.md** files
2. Compares timestamps with corresponding **CLAUDE.md** files
3. Imports newer Windsurf content into Claude context
4. Converts Windsurf rule format → Claude markdown format
## Real-time Export (Claude → Windsurf)

When you edit context files in Claude Code, the **PostToolUse** hook:

1. Detects when **CLAUDE.md** or other context files are modified
2. Immediately exports changes to corresponding **WINDSURF.md** files
3. Converts Claude markdown format → Windsurf rules format
4. Preserves Windsurf-specific formatting and structure
## Content Mapping

The system intelligently maps equivalent sections:

* **Architecture Guidelines** ↔ **Project Structure**
* **Technology Rules** ↔ **Tech Stack**
* **Workflows** ↔ **Commands**
* **Project Setup Rules** ↔ **Setup**
## Conflict Resolution

* **Timestamp-based**: Newer files always win
* **Sync metadata**: Tracks last sync time and source
* **Format preservation**: Each tool maintains its preferred format
* **Graceful fallback**: Continues on individual file failures
## Hook Configuration

Add these hooks to your Claude Code settings:

``**json
{
  "SessionStart": [
    {
      "matcher": "startup",
      "hooks": [
        {
          "type": "command",
          "command": "PROJECT_DIR=\"$PWD\" && cd ~/dotfiles/ai/.config/ai/sync && pnpm dlx tsx src/windsurf-to-claude.ts \"$PROJECT_DIR\""
        }
      ]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Edit|Write|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "command": "PROJECT_DIR=\"$PWD\" && cd ~/dotfiles/ai/.config/ai/sync && pnpm dlx tsx src/claude-to-windsurf.ts \"${filePath}\" \"$PROJECT_DIR\""
        }
      ]
    }
  ]
}
**``
## Global Configuration Loading

The system also includes **claude-session-start.ts** which loads global AI configurations from **~/.config/ai/global/**:

``**json
{
  "SessionStart": [
    {
      "matcher": "startup",
      "hooks": [
        {
          "type": "command",
          "command": "cd ~/dotfiles/ai/.config/ai/sync && pnpm dlx tsx src/claude-session-start.ts"
        }
      ]
    }
  ]
}
**``

This loads global preferences in priority order:

1. **JSON files** first (code-style.json, mcp.json, etc.)
2. **TOML files** second (future expansion)
3. **Markdown files** last (typescript-preferences.md, react-preferences.md, etc.)
## Architecture


## TypeScript Services (Following OOP Patterns)

* **ContextFileDetector**: Discovers and classifies context files
* **ContentMerger**: Handles bidirectional format conversion
* **SyncOrchestrator**: Coordinates all sync operations
* **FileOperations**: Manages file I/O with proper error handling
## File Structure

``**
src/
├── services/
│   ├── context-file-detector.ts    # File discovery & classification
│   ├── content-merger.ts           # Format conversion logic
│   └── sync-orchestrator.ts        # Main sync coordination
├── types/
│   ├── config.ts                   # Global config types
│   └── sync.ts                     # Sync-specific types
├── utils/
│   └── file-operations.ts          # File I/O utilities
├── claude-session-start.ts         # Global config loader
├── claude-to-windsurf.ts           # PostToolUse hook script
└── windsurf-to-claude.ts           # SessionStart hook script
**``
## Design Principles

* **Dependency Injection**: Services composed via constructor injection
* **Fail Fast**: Input validation with proper error handling  
* **Immutable Types**: Readonly properties prevent accidental mutation
* **Result Types**: No throwing errors, explicit success/failure states
* **Single Responsibility**: Each service has one clear purpose
## Core Service Classes

When modifying the sync system, understand these key components:

* **ContextFileDetector**: Discovers uppercase **.md** files, excludes documentation files, extracts sync metadata
* **ContentMerger**: Handles bidirectional format conversion between Claude/Windsurf, manages YAML frontmatter
* **SyncOrchestrator**: Main coordination logic, timestamp comparison, file conflict resolution
* **FileOperations**: File I/O with proper error handling and retry logic
## File Type Classification

The system recognizes these context file types:
* **claude**: Root-level **CLAUDE.md** files
* **windsurf**: Files in **.windsurf/rules/** or named **WINDSURF.md**
* **claude-command**: Files in **.claude/commands/** directories
* **windsurf-workflow**: Files in **.windsurf/workflows/** directories
* **other**: Other uppercase **.md** files
## Usage Examples


## Manual Sync Testing

```bash
## Test Windsurf → Claude import

cd ~/dotfiles/ai/.config/ai/sync && pnpm dlx tsx src/windsurf-to-claude.ts
## Test Claude → Windsurf export

cd ~/dotfiles/ai/.config/ai/sync && pnpm dlx tsx src/claude-to-windsurf.ts CLAUDE.md
## Load global configurations

cd ~/dotfiles/ai/.config/ai/sync && pnpm dlx tsx src/claude-session-start.ts
```
## Sync Metadata Format

Each synced file includes metadata headers:

``**markdown
**``
## Excluded Files

The system automatically ignores common documentation files:

* README.md, CHANGELOG.md, LICENSE.md
* CONTRIBUTING.md, SECURITY.md, SUPPORT.md
* FAQ.md, TODO.md, NOTES.md, LOGS.md
* And other standard project documentation
## Benefits

* **Seamless Workflow**: Edit in either tool, changes sync automatically
* **No Context Loss**: Never lose project context when switching tools
* **Format Optimization**: Each tool sees content in its preferred format
* **Conflict Prevention**: Timestamp-based resolution prevents overwrites
* **Zero Maintenance**: Runs automatically via hooks, no manual intervention
## Development

This project follows TypeScript best practices:

* Alphabetical property ordering in all interfaces
* Interface extends over intersection types
* Readonly properties by default
* Named exports only
* Proper JSDoc documentation
* Discriminated unions for state management
## Debugging

Use these debugging techniques when troubleshooting:

```bash
## Check sync metadata in files

grep -A2 "Last synced:" *.md
## Test individual file detection

tsx src/services/context-file-detector.ts
## Monitor hook execution

tail -f ~/.claude/logs/hooks.log
```
## Extension Points

To extend the sync system:

1. **New File Types**: Add to **ContextFileType** in **src/types/sync.ts**
2. **Format Converters**: Extend **ContentMerger** methods for new formats
3. **Detection Rules**: Modify **ContextFileDetector.determineFileType()**
4. **Excluded Files**: Update **EXCLUDED_FILES** constant

The sync system ensures you can seamlessly switch between Claude Code and Windsurf IDE while maintaining perfect context continuity.