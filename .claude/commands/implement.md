---
description: Implement a plan from .claude/plans/
argument-hint: <path-to-plan.md>
---

# Implement the following plan

Follow the `Instructions` to implement the `Plan` then `Report` the completed work.

## Instructions

- Read the plan, ultrathink about the plan and implement the plan.
- Follow all validation commands specified in the plan.
- Test each change before moving to the next step.

## Dotfiles Validation Commands

Use these commands to validate changes:

### Karabiner
```bash
cd karabiner/.config/karabiner && goku
launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server
```

### Hammerspoon
```bash
hs -c "hs.reload()"
```

### AeroSpace
```bash
aerospace reload-config
```

### WezTerm
```bash
wezterm show-config
```

### Stow
```bash
stow -n -v <package>  # Dry run
stow -R <package>     # Re-stow
```

### LaunchAgents
```bash
launchctl bootout gui/$(id -u)/<agent> 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/<agent>.plist
```

## Plan

$ARGUMENTS

## Report

- Summarize the work you've just done in a concise bullet point list.
- Report the files and total lines changed with `git diff --stat`
