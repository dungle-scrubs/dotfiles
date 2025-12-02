# Context Prime

This file provides essential commands to quickly understand this dotfiles repository structure and key configurations. The commands are organized in two sections: "Run Now" for immediate context and "Run As Needed" for deeper exploration.

## Run Now - Essential Project Context

Run these commands to get a high-level understanding of the project:

```bash
# Get a concise view of the stow packages
ls -la

# View the project's key configuration
cat CLAUDE.md

# View the README for setup instructions
cat README.md

# See which packages are currently stowed (symlinked)
ls -la ~/.config/ | grep -E "^l" | head -20
```

## Run As Needed - Deeper Investigation

### Stow Package Management

```bash
# Check stow status for a package
stow -n -v <package>  # Dry run to see what would be linked

# Re-stow all packages (refresh symlinks)
for dir in */; do stow -R "${dir%/}"; done

# Find broken symlinks in ~/.config
find ~/.config -xtype l 2>/dev/null
```

### Karabiner (Goku)

```bash
# View current Karabiner configuration
cat karabiner/.config/karabiner/karabiner.edn

# Compile Karabiner config
cd karabiner/.config/karabiner && goku

# Force reload Karabiner
launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server
```

### Hammerspoon

```bash
# View Hammerspoon config
cat hammerspoon/.config/hammerspoon/init.lua

# Reload Hammerspoon
hs -c "hs.reload()"

# Check Hammerspoon console for errors
hs -c "hs.console.hswindow():focus()"
```

### AeroSpace

```bash
# View AeroSpace config
cat aerospace/.config/aerospace/aerospace.toml

# Reload AeroSpace config
aerospace reload-config

# List current workspaces
aerospace list-workspaces --all
```

### WezTerm

```bash
# View WezTerm config structure
ls -la wezterm/.config/wezterm/

# Check WezTerm config for errors
wezterm show-config 2>&1 | head -20
```

### Homebrew

```bash
# View Brewfile contents
cat homebrew/Brewfile

# Check what's installed vs Brewfile
brew bundle check --file=homebrew/Brewfile

# Install missing packages
brew bundle --file=homebrew/Brewfile
```

### LaunchAgents

```bash
# List LaunchAgents in this repo
ls -la launchagents/Library/LaunchAgents/

# Check loaded LaunchAgents
launchctl list | grep -E "local\.|kevin"

# View LaunchAgent status
launchctl print gui/$(id -u)/<agent-name>
```

### Git Information

```bash
# Show recent commits
git log --oneline -n 10

# Show modified files
git status

# Show diff of changes
git diff
```

## Key Integration Points

- **AeroSpace + Hammerspoon**: Service mode (`Alt+Shift+;`) triggers Hammerspoon overlay
- **AeroSpace + JankyBorders**: Borders start on AeroSpace startup
- **Hammerspoon MenuHammer**: Modal menu via `Ctrl+Alt+Space`
- **Karabiner home row mods**: A/S/D/F and J/K/L/; as modifiers when held

## Package-Specific CLAUDE.md Files

Some packages have their own CLAUDE.md with detailed instructions:

```bash
# Find all CLAUDE.md files
find . -name "CLAUDE.md" -not -path "./.git/*"
```
