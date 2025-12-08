---
description: Create a plan for a dotfiles task (feature, bug fix, or refactor)
argument-hint: <task-description>
---

# Task Planning

Create a new plan in `.claude/plans/*.plan.md` to implement the `Task`.

## Instructions

- Create the plan in the `.claude/plans/<NN>_<task-name>.plan.md` file where:
  - `<NN>` is a 2-digit sequential number (01, 02, 03, etc.) based on existing plans in the directory
  - `<task-name>` is a kebab-case name based on the task (e.g., `aerospace-hotkeys`, `hammerspoon-refactor`)
  - Example: `01_aerospace-hotkeys.plan.md`, `02_hammerspoon-refactor.plan.md`
- Check existing plans in `.claude/plans/` to determine the next available number
- Use your reasoning model: ultrathink about the requirements, design, and implementation approach.
- **Interactive Mode Handling:**
  - If in interactive mode: **BEFORE entering plan mode**, analyze the task and use the `AskUserQuestion` tool to gather clarifying information. You MUST ask questions when:
    - The task could be implemented in multiple valid ways
    - The scope is unclear
    - Technical decisions need user preferences or input
    - Requirements are ambiguous or could be interpreted differently
    - You're making assumptions that could be wrong
    - There are tradeoffs the user should decide on
  - After getting answers, THEN enter plan mode and create the detailed plan.
  - If NOT in interactive mode: Proceed with planning based on available information without prompting.

## Dotfiles-Specific Considerations

When planning, consider these integration points:

- **Karabiner**: Always edit `karabiner.edn` (Goku), never `karabiner.json` directly
- **Hammerspoon**: Lua-based, check for module dependencies
- **AeroSpace**: TOML config, verify keybinding conflicts
- **WezTerm**: Modular Lua config structure
- **Stow**: Symlink management, check for conflicts
- **LaunchAgents**: plist files, proper loading/unloading

## Relevant Documentation

Start by reading:
- `CLAUDE.md` - Repository overview
- Package-specific `CLAUDE.md` files (if they exist)

## Task

$ARGUMENTS

## CRITICAL: Do NOT Implement

**After creating the plan file, STOP. Do NOT begin implementation.**

- Your task is ONLY to create the plan document
- Implementation requires explicit user approval
- Report the plan location and wait for user to decide next steps
- NEVER use ExitPlanMode to proceed with implementation

## Report

- Summarize the work you've just done in a concise bullet point list.
- Include a path to the plan you created in the `.claude/plans/<NN>_<task-name>.plan.md` file.
- Ask the user if they want to proceed with implementation.
