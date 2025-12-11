# Refactor: Replace Windsurf with Cursor in Project Launcher

## Refactor Description

Update the Hammerspoon projectLauncher module to use Cursor instead of Windsurf as the code editor. This includes changing the config key, app path, and app name references in both `init.lua` and the MenuHammer config.

## Motivation

The user has switched from Windsurf to Cursor as their primary code editor. The projectLauncher's "Fuse (DeckFusion)" auto-open should launch Cursor instead of Windsurf to match the current workflow.

## Current State Analysis

**init.lua (lines 469-480):**
```lua
if config.windsurf then
    table.insert(steps, function(next)
        local dir = config.windsurf.dir:gsub("^~", os.getenv("HOME"))
        launchAndMove(
            function()
                hs.task.new("/Applications/Windsurf.app/Contents/Resources/app/bin/windsurf", nil, { dir }):start()
            end,
            "Windsurf",
            config.windsurf.workspace,
            next
        )
    end)
end
```

**MenuConfigDefaults.lua (line 1277):**
```lua
windsurf = { dir = "~/dev/deckfusion", workspace = "X" },
```

## Target State

Replace all Windsurf references with Cursor:
- Config key: `windsurf` → `cursor`
- App path: `/Applications/Windsurf.app/...` → `/Applications/Cursor.app/Contents/Resources/app/bin/cursor`
- App name: `"Windsurf"` → `"Cursor"`

## Behavior Preservation Strategy

The behavior is intentionally changing from Windsurf to Cursor. However, the *pattern* of behavior remains identical:
- Launch editor at specified directory
- Wait for app window to appear
- Move window to specified AeroSpace workspace
- Continue to next step in project launch sequence

Validation will confirm Cursor launches correctly and moves to the expected workspace.

## Impact Assessment

- **projectLauncher module**: Config key renamed, app binary path changed
- **MenuHammer Fuse project config**: `windsurf` key renamed to `cursor`
- **User workflow**: Fuse project will open Cursor instead of Windsurf

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Cursor CLI path incorrect | Low | High | Verified path exists at `/Applications/Cursor.app/Contents/Resources/app/bin/cursor` |
| Cursor app name mismatch | Low | Medium | Verify exact app name string for `hs.application.get()` |
| Workspace assignment fails | Low | Low | Same mechanism as Windsurf, already working |

## Scope Definition

### In Scope
- Replace `windsurf` config key with `cursor` in projectLauncher
- Update Cursor app binary path
- Update Cursor app name for window detection
- Update Fuse project config in MenuConfigDefaults.lua

### Out of Scope
- Adding generic editor support (user chose replacement approach)
- Keeping Windsurf as an option
- Updating any other project configs (only Fuse/deckfusion affected)
- Updating config comment examples (line 418 in init.lua)

## Affected Packages

- `hammerspoon` - main config and MenuHammer spoon

## Relevant Files

### hammerspoon/.config/hammerspoon/init.lua
Contains the `projectLauncher` module with Windsurf launch logic (lines 469-480). This file needs the config key, app path, and app name updated.

### hammerspoon/.config/hammerspoon/Spoons/MenuHammer.spoon/MenuConfigDefaults.lua
Contains the Fuse project configuration (line 1277). The `windsurf` key needs to be renamed to `cursor`.

## Implementation Plan

### Phase 1: Preparation & Baseline
1. Document current behavior (Windsurf launches on Fuse project open)
2. Verify Cursor app is installed and CLI path is correct

### Phase 2: Incremental Refactoring
1. Update init.lua: Change `config.windsurf` to `config.cursor`
2. Update init.lua: Change Cursor app binary path
3. Update init.lua: Change app name from "Windsurf" to "Cursor"
4. Update MenuConfigDefaults.lua: Change `windsurf` key to `cursor`

### Phase 3: Validation & Cleanup
1. Reload Hammerspoon config
2. Test Fuse project launch via MenuHammer
3. Verify Cursor opens at correct directory and moves to workspace X

## Step by Step Tasks

### Step 1: Update projectLauncher in init.lua
- Change `config.windsurf` → `config.cursor` (line 469, 470, 471, 477)
- Change app path to `/Applications/Cursor.app/Contents/Resources/app/bin/cursor` (line 474)
- Change app name `"Windsurf"` → `"Cursor"` (line 476)

### Step 2: Update Fuse project config in MenuConfigDefaults.lua
- Change `windsurf = { dir = "~/dev/deckfusion", workspace = "X" }` → `cursor = { ... }` (line 1277)

### Step 3: Reload and Test
- Run `hs -c "hs.reload()"` to reload Hammerspoon
- Open MenuHammer (Ctrl+Alt+Space)
- Navigate to Projects → Fuse (f)
- Verify Cursor launches at `~/dev/deckfusion` and moves to workspace X

### Step 4: Run Validation Commands
- Execute all validation commands below

## Testing Strategy

### Behavior Verification
1. Launch Fuse project via MenuHammer
2. Observe Cursor app opens (not Windsurf)
3. Verify Cursor opens at `~/dev/deckfusion` directory
4. Verify Cursor window moves to AeroSpace workspace X

### Config Validation
- Hammerspoon console shows no errors on reload
- No Lua syntax errors

### Regression Testing
- Other projectLauncher features (WezTerm, Arc, OrbStack) still work
- MenuHammer menu navigation unaffected

## Acceptance Criteria

1. [ ] Fuse project launch opens Cursor (not Windsurf)
2. [ ] Cursor opens at `~/dev/deckfusion` directory
3. [ ] Cursor window moves to AeroSpace workspace X
4. [ ] Hammerspoon reloads without errors
5. [ ] Alert shows "Fuse loaded" after launch completes
6. [ ] Final focus returns to WezTerm on workspace T

## Validation Commands

### Hammerspoon
```bash
# Reload Hammerspoon config
hs -c "hs.reload()"

# Check console for errors (in Hammerspoon Console)
# No Lua errors should appear
```

### Test Project Launch
```bash
# Manually test via Hammerspoon (after MenuHammer entry)
hs -c 'projectLauncher.open({ name = "Test", cursor = { dir = "~/dev/deckfusion", workspace = "X" } })'
```

### Verify Cursor CLI
```bash
# Confirm Cursor CLI works
/Applications/Cursor.app/Contents/Resources/app/bin/cursor --version
```

## Notes

- The comment on line 418 in init.lua still references `windsurf` as an example config option. This is out of scope but could be updated for consistency in a future cleanup.
- If Cursor app name for `hs.application.get()` differs from "Cursor", it may need to be discovered via `hs.application.runningApplications()` while Cursor is open.
