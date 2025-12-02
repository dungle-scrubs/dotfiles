# Feature Planning

Create a new plan to implement the `Feature` using the exact specified markdown `Plan Format`. Follow the `Instructions` to create the plan and use the `Relevant Files` to focus on the right areas.

## Instructions

- IMPORTANT: You're writing a plan to implement a new dotfiles feature based on the `Feature` that will add value.
- IMPORTANT: The `Feature` describes what will be implemented but remember we're creating the plan, not implementing the feature directly.
- Use the `Plan Format` below to create the plan.
- Research the codebase to understand existing patterns, architecture, and conventions before planning.
- IMPORTANT: Replace every `<placeholder>` in the `Plan Format` with the requested value.
- Use your reasoning model: THINK HARD about the requirements, design, and implementation approach.
- Follow existing patterns and conventions in each configuration.
- Design for maintainability - dotfiles should be easy to understand and modify.

## Dotfiles-Specific Guidelines

- **Karabiner**: Always edit `karabiner.edn` (Goku format), never `karabiner.json` directly
- **Hammerspoon**: Follow Lua patterns, use modular design for complex features
- **AeroSpace**: TOML config, check for keybinding conflicts with Karabiner
- **WezTerm**: Modular Lua structure (design, keybinds, status modules)
- **Stow**: Follow XDG conventions (`<package>/.config/<package>/`)
- **LaunchAgents**: Use proper plist structure, ensure proper permissions
- **Zsh**: Requires `ZDOTDIR` setup, use XDG paths

## Relevant Files

Focus on the following based on the feature type:

### Core Documentation
- `CLAUDE.md` - Repository overview and common commands
- `README.md` - Setup instructions

### Karabiner (Keyboard Remapping)
- `karabiner/.config/karabiner/karabiner.edn` - Goku EDN source
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

### Homebrew
- `homebrew/Brewfile` - Package manifest

## Plan Format

```md
# Feature: <feature name>

## Feature Description
<describe the feature in detail, including its purpose and value>

## User Story
As a <type of user>
I want to <action/goal>
So that <benefit/value>

## Problem Statement
<clearly define the specific problem or opportunity this feature addresses>

## Solution Statement
<describe the proposed solution approach and how it solves the problem>

## Affected Packages
<list which stow packages will be modified or created>

## Integration Points
<describe how this feature integrates with existing tools - e.g., AeroSpace + Hammerspoon, Karabiner + other tools>

## Relevant Files
Use these files to implement the feature:

<find and list the files that are relevant to the feature and describe why they are relevant. If new files need to be created, list them in an h3 'New Files' section.>

## Implementation Plan
### Phase 1: Foundation
<describe the foundational work needed before implementing the main feature>

### Phase 2: Core Implementation
<describe the main implementation work for the feature>

### Phase 3: Integration & Testing
<describe how the feature will integrate with existing functionality and be tested>

## Step by Step Tasks
IMPORTANT: Execute every step in order, top to bottom.

<list step by step tasks as h3 headers plus bullet points. Order matters - start with foundational changes, then specific implementation. Your last step should be running the `Validation Commands`.>

## Testing Strategy
### Manual Testing
<describe manual tests to verify the feature works>

### Config Validation
<describe config validation steps for each tool>

### Edge Cases
<list edge cases that need to be tested>

## Acceptance Criteria
<list specific, measurable criteria that must be met for the feature to be considered complete>

## Validation Commands
Execute every command to validate the feature works correctly.

### Karabiner
- `cd karabiner/.config/karabiner && goku` - Compile Goku config
- `launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server` - Reload Karabiner

### Hammerspoon
- `hs -c "hs.reload()"` - Reload Hammerspoon config

### AeroSpace
- `aerospace reload-config` - Reload AeroSpace config

### WezTerm
- `wezterm show-config` - Validate WezTerm config

### Stow
- `stow -n -v <package>` - Dry run to check symlinks
- `stow -R <package>` - Re-stow to refresh symlinks

### LaunchAgents
- `launchctl bootout gui/$(id -u)/<agent> 2>/dev/null; launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/<agent>.plist` - Reload agent

## Notes
<optionally list any additional notes, future considerations, or context relevant to the feature>
```

## Feature

$ARGUMENTS
