---
description: Create a new branch and implement a plan in one flow
argument-hint: [implementation-plan]
---

# Branch and Implement

Create a new git branch from latest main and implement a plan in one seamless flow.

## Workflow

1. **Understand the plan** - Read and analyze what needs to be implemented
2. **Derive branch name** - Generate a kebab-case branch name from the plan
3. **Create branch** - Switch to main, pull latest, create and switch to new branch
4. **Implement** - Execute the implementation plan
5. **Report** - Summarize completed work

## Variables

- `$ARGUMENTS`: The implementation plan or feature description

## Instructions

### Step 1: Analyze Plan

Read the provided plan and ultrathink about:
- What is being implemented
- A concise kebab-case branch name (e.g., `add-aerospace-hotkeys`, `fix-hammerspoon-eventtap`)

### Step 2: Create Branch

Execute these git commands:

```bash
git checkout main
git pull origin main
git checkout -b [derived-branch-name]
```

### Step 3: Implement

Follow the plan from `$ARGUMENTS` and implement the changes.

### Step 4: Validate

Run the appropriate validation commands based on what was changed:

#### Karabiner
```bash
cd karabiner/.config/karabiner && goku
launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server
```

#### Hammerspoon
```bash
hs -c "hs.reload()"
```

#### AeroSpace
```bash
aerospace reload-config
```

#### WezTerm
```bash
wezterm show-config
```

#### Stow
```bash
stow -n -v <package>  # Dry run
stow -R <package>     # Re-stow
```

#### LaunchAgents
```bash
launchctl bootout gui/$(id -u)/<agent> 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/<agent>.plist
```

## Plan

$ARGUMENTS

## Report

- State the branch name created
- Summarize the work completed in a concise bullet point list
- Report the files and total lines changed with `git diff --stat`
