# ===== Environment Variables =====
export XDG_CONFIG_HOME="$HOME/.config"
export GOKU_EDN_CONFIG_FILE="$XDG_CONFIG_HOME/karabiner/karabiner.edn"
export LANG=en_US.UTF-8
export EDITOR=/opt/homebrew/bin/nvim
export HOMEBREW_NO_ENV_HINTS=1
export IDEAVIM_RC="$HOME/.config/ideavim/.ideavimrc"
export PYENV_ROOT="$HOME/.pyenv"
export CLAUDE_CONFIG_DIR="$HOME/.claude"

# Environment variables moved from .zshrc
export STARSHIP_CONFIG=$HOME/.config/starship/starship.toml
export DISABLE_AUTO_TITLE="true"
export COMPLETION_WAITING_DOTS="true"
export HISTFILE="$ZDOTDIR/.zsh_history"
export ATUIN_CONFIG_DIR="$HOME/.config/atuin"
export BAT_THEME="Monokai Extended"
export BAT_STYLE="full"
export PAGER="less -R"
export BAT_PAGER="less -RF"
export MCP_DEBUG=false
export NODE_OPTIONS="--max-old-space-size=16384"

# ===== Path Management =====
typeset -U path_dirs
path_dirs=(
  "$HOME/Library/Python/3.13/bin",
  "/opt/homebrew/bin",
  "/opt/homebrew/opt/lua-language-server",
  "/Library/Frameworks/Python.framework/Versions/3.13/bin",
  "$PYENV_ROOT/bin", 
  "$HOME/Library/pnpm",
  "$HOME/Library/Application Support/Herd/bin/",
  "$HOME/.local/bin",
  "$HOME/.config/scripts/",
  "$HOME/.atuin/bin",
  "$HOME/go/bin",
  "$HOME/.npm-global/bin",
  "$HOME/Library/pnpm",
  "$HOME/.codeium/windsurf/bin",
  "$HOME/ai-stuff/bin",
  "$HOME/.claude/local",
  "$HOME/.claude-mod/bin"
)

export PATH=$(printf "%s:" "${path_dirs[@]}")$PATH
# Clean PATH of any commas that might have been introduced by:
# - Claude Code shell snapshots containing corrupted PATH with agent-x/bin,
# - Previous development setups that incorrectly used PATH=$PATH,/path syntax
# - Applications that modify PATH with trailing commas
export PATH=$(echo "$PATH" | tr ',' ' ' | tr -s ' ' ':' | sed 's/::/:/g')
  
# Homebrew path (calculate once)
eval "$(/opt/homebrew/bin/brew shellenv)"

# ===== Language Environment Setup =====
 
# PHP (Herd)
export HERD_PHP_82_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/82/"
export HERD_PHP_84_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/84/"

# PNPM
export PNPM_HOME="$HOME/Library/pnpm"

# NVM environment
export NVM_LAZY_LOAD=true
export NVM_DIR="$HOME/.nvm"

# Ruby environment
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# Lua environment
if command -v luarocks &> /dev/null; then
  eval "$(luarocks path --bin)"
fi

# Pyenv
eval "$(pyenv init -)"

# ===== Private Environment Variables =====
# Load private environment variables (not version controlled)
[ -f "$ZDOTDIR/.zprofile.private" ] && source "$ZDOTDIR/.zprofile.private"


# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
