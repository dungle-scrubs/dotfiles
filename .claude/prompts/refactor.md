# Refactoring Planning

Create a new plan to execute the `Refactor` using the exact specified markdown `Plan Format`. Follow the `Instructions` to create the plan and use the `Relevant Files` to focus on the right areas.

## Instructions

- IMPORTANT: You're writing a plan to refactor dotfiles configuration based on the `Refactor` that will improve organization, maintainability, or clarity.
- IMPORTANT: The `Refactor` describes the work but remember we're creating the plan, not executing the refactor directly.
- Use the `Plan Format` below to create the plan.
- Research the codebase thoroughly to understand the current implementation before planning.
- **CRITICAL: Refactoring means improving structure/organization WITHOUT changing behavior.** Keybindings, automations, and functionality should work identically after the refactor.
- IMPORTANT: Replace every `<placeholder>` in the `Plan Format` with the requested value.
- Use your reasoning model: THINK HARD about what's wrong with the current structure and what would be better.
- **CRITICAL: Behavior preservation is the PRIMARY constraint.** All configs must work identically before and after.
- **CRITICAL: Plan incremental, testable steps.** Each step should be independently verifiable.
- **CRITICAL: Define scope boundaries.** Refactors can expand - be disciplined about what's IN and OUT of scope.
- Follow existing patterns and conventions in the codebase.

## Common Dotfiles Refactor Types

Consider which type of refactor applies:

- **Modularization**: Large monolithic configs → smaller, focused modules
- **Consolidation**: Duplicate configurations → shared patterns
- **Reorganization**: Poor directory structure → better XDG organization
- **Simplification**: Over-engineered configs → cleaner, simpler implementation
- **Documentation**: Missing/poor docs → clear inline comments and CLAUDE.md files
- **Stow Structure**: Non-standard package layout → proper stow conventions
- **Integration Cleanup**: Tangled integrations → clear separation of concerns

## Relevant Files

Focus on the following based on the refactor type:

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

## Plan Format

```md
# Refactor: <refactor name>

## Refactor Description
<describe what configs are being refactored and what improvements are being made>

## Motivation
<explain WHY this refactor is needed - organization, maintainability, clarity, preparing for new features, reducing complexity>

## Current State Analysis
<analyze the current implementation - what's disorganized, hard to maintain, overly complex, or poorly structured>

## Target State
<describe what the configs should look like after refactoring - better organization, clearer structure, improved maintainability>

## Behavior Preservation Strategy
<explain how we'll ensure all keybindings, automations, and functionality work identically after the refactor>

## Impact Assessment
<what packages, configs, or integrations will be affected by this refactor>

## Risk Analysis
<what could accidentally break, what are the highest-risk changes, how will we mitigate>

## Scope Definition
### In Scope
<explicitly list what WILL be refactored>

### Out of Scope
<explicitly list what will NOT be touched - prevents scope creep>

## Affected Packages
<list which stow packages will be modified>

## Relevant Files
Use these files to execute the refactor:

<find and list the files that will be refactored and explain why each is relevant. If new files need to be created (e.g., new modules, CLAUDE.md files), list them in an h3 'New Files' section.>

## Implementation Plan
### Phase 1: Preparation & Baseline
<describe preparatory work - document current behavior, create backups if needed>

### Phase 2: Incremental Refactoring
<describe the main refactoring work broken into small, testable increments>

### Phase 3: Validation & Cleanup
<describe how the refactor will be validated and any cleanup work>

## Step by Step Tasks
IMPORTANT: Execute every step in order, top to bottom.

<list step by step tasks as h3 headers plus bullet points. Order matters - start with preparation, then incremental refactoring (each step should be testable), then validation. Your last step should be running the `Validation Commands`.>

## Testing Strategy
### Behavior Verification
<describe how to verify all functionality works identically before and after>

### Config Validation
<describe config validation steps for each affected tool>

### Regression Testing
<describe tests to ensure nothing broke during the refactor>

## Acceptance Criteria
<list specific, measurable criteria that must be met for the refactor to be considered successful>

## Validation Commands
Execute every command to validate the refactor succeeded with zero behavior changes.

### Karabiner
- `cd karabiner/.config/karabiner && goku` - Compile Goku config
- `launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server` - Reload Karabiner
- Test all keybindings work as before

### Hammerspoon
- `hs -c "hs.reload()"` - Reload Hammerspoon config
- Check console for errors
- Test all automations work as before

### AeroSpace
- `aerospace reload-config` - Reload AeroSpace config
- Test all window management works as before

### WezTerm
- `wezterm show-config` - Validate config syntax
- Verify terminal appearance and keybindings unchanged

### Stow
- `stow -n -v <package>` - Dry run to check symlinks
- `stow -R <package>` - Re-stow to refresh symlinks

## Notes
<optionally list any additional notes, trade-offs made, future refactoring opportunities, or context>
```

## Refactor

$ARGUMENTS
