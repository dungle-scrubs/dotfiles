# Bug Planning

Create a new plan to resolve the `Bug` using the exact specified markdown `Plan Format`. Follow the `Instructions` to create the plan and use the `Relevant Files` to focus on the right areas.

## Instructions

- IMPORTANT: You're writing a plan to resolve a dotfiles/macOS configuration bug based on the `Bug` description.
- IMPORTANT: The `Bug` describes the issue but remember we're creating the plan, not fixing the bug directly.
- Use the `Plan Format` below to create the plan.
- Research the codebase to understand the bug, reproduce it, and identify the root cause before planning the fix.
- IMPORTANT: Replace every `<placeholder>` in the `Plan Format` with the requested value.
- Use your reasoning model: THINK HARD about the bug, its root cause, and the steps to fix it properly.
- IMPORTANT: Be surgical with your bug fix - solve the bug at hand without falling off track.
- IMPORTANT: We want the minimal number of changes that will fix the bug without introducing new issues.
- Follow existing patterns and conventions in each configuration.

## Dotfiles-Specific Guidelines

- **Karabiner**: Always edit `karabiner.edn`, never `karabiner.json` directly. Check for conflicting key mappings.
- **Hammerspoon**: Check for Lua syntax errors, module loading issues, and API deprecations.
- **AeroSpace**: Validate TOML syntax, check for conflicting keybindings with Karabiner.
- **WezTerm**: Check Lua config syntax, ensure all required modules exist.
- **Stow**: Verify symlinks are correct and no conflicts exist.
- **LaunchAgents**: Check plist syntax, verify paths, check launchctl errors.

## Relevant Files

Focus on the following based on the bug type:

### Core Documentation
- `CLAUDE.md` - Repository overview and common commands
- `README.md` - Setup instructions

### Karabiner (Keyboard Remapping)
- `karabiner/.config/karabiner/karabiner.edn` - Goku EDN source (edit this)
- `karabiner/.config/karabiner/karabiner.json` - Compiled output (never edit)
- `karabiner/.config/karabiner/CLAUDE.md` - Karabiner-specific guidance

### Hammerspoon (macOS Automation)
- `hammerspoon/.config/hammerspoon/init.lua` - Main config
- `hammerspoon/.config/hammerspoon/CLAUDE.md` - Hammerspoon-specific guidance

### AeroSpace (Window Management)
- `aerospace/.config/aerospace/aerospace.toml` - Main config

### WezTerm (Terminal)
- `wezterm/.config/wezterm/init.lua` - Main config
- `wezterm/.config/wezterm/*.lua` - Modular configs

### Zsh (Shell)
- `zsh/.config/zsh/.zshrc` - Main shell config

### LaunchAgents (Background Services)
- `launchagents/Library/LaunchAgents/` - plist files

## Plan Format

```md
# Bug: <bug name>

## Bug Description
<describe the bug in detail, including symptoms and expected vs actual behavior>

## Problem Statement
<clearly define the specific problem that needs to be solved>

## Solution Statement
<describe the proposed solution approach to fix the bug>

## Steps to Reproduce
<list exact steps to reproduce the bug>

## Hypotheses & Confidence Scores

List each hypothesis for the bug's root cause with a confidence score and proposed solution.

| # | Hypothesis | Confidence | Proposed Solution | Solution Confidence |
|---|------------|------------|-------------------|---------------------|
| 1 | <hypothesis description> | <HIGH/MEDIUM/LOW> | <proposed fix> | <HIGH/MEDIUM/LOW> |
| 2 | <hypothesis description> | <HIGH/MEDIUM/LOW> | <proposed fix> | <HIGH/MEDIUM/LOW> |

**Confidence Scale:**
- **HIGH (80-100%)**: Strong evidence from code analysis, logs, or reproduction
- **MEDIUM (50-79%)**: Reasonable inference but needs verification
- **LOW (0-49%)**: Speculative, requires investigation to confirm

**Selected Hypothesis:** <number and brief justification for selection>

## Root Cause Analysis
<analyze and explain the confirmed root cause of the bug based on the selected hypothesis>

## Affected Packages
<list which stow packages are affected>

## Relevant Files
Use these files to fix the bug:

<find and list the files that are relevant to the bug and describe why they are relevant. If new files need to be created, list them in an h3 'New Files' section.>

## Implementation Plan
### Phase 1: Investigation
<describe the investigation work needed to understand the bug fully>

### Phase 2: Bug Fix
<describe the specific changes needed to fix the bug>

### Phase 3: Validation
<describe how the fix will be validated and tested>

## Step by Step Tasks
IMPORTANT: Execute every step in order, top to bottom.

<list step by step tasks as h3 headers plus bullet points. Order matters - start with investigation, then fix, then validation. Your last step should be running the `Validation Commands`.>

## Testing Strategy
### Manual Testing
<describe manual tests to verify the bug fix>

### Config Validation
<describe config validation steps (syntax checks, reload commands)>

### Regression Tests
<describe tests to ensure the fix doesn't break existing functionality>

### Edge Cases
<list edge cases that need to be tested>

## Acceptance Criteria
<list specific, measurable criteria that must be met for the bug to be considered fixed>

## Validation Commands
Execute every command to validate the bug is fixed with zero regressions.

### Karabiner
- `cd karabiner/.config/karabiner && goku` - Compile Goku config
- `launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server` - Reload Karabiner

### Hammerspoon
- `hs -c "hs.reload()"` - Reload Hammerspoon config
- Check Hammerspoon console for errors

### AeroSpace
- `aerospace reload-config` - Reload AeroSpace config

### WezTerm
- `wezterm show-config` - Validate WezTerm config syntax

### Stow
- `stow -n -v <package>` - Dry run to check symlinks
- `stow -R <package>` - Re-stow to refresh symlinks

### LaunchAgents
- `launchctl bootout gui/$(id -u)/<agent> 2>/dev/null; launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/<agent>.plist` - Reload agent
- `launchctl print gui/$(id -u)/<agent>` - Check agent status

## Notes
<optionally list any additional notes, future considerations, or context relevant to the bug>
```

## Bug

$ARGUMENTS
