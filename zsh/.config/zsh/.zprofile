# ===== Core Environment =====
export XDG_CONFIG_HOME="$HOME/.config"
export DOTFILES="$HOME/dev/dotfiles"
export LANG=en_US.UTF-8
export EDITOR=/opt/homebrew/bin/nvim
export PAGER="less -R"

# ===== XDG Paths =====
export GOKU_EDN_CONFIG_FILE="$XDG_CONFIG_HOME/karabiner/karabiner.edn"
export IDEAVIM_RC="$XDG_CONFIG_HOME/ideavim/.ideavimrc"
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
export ATUIN_CONFIG_DIR="$XDG_CONFIG_HOME/atuin"
export CLAUDE_CONFIG_DIR="$HOME/.claude"

# ===== Shell Behavior =====
export HISTFILE="$ZDOTDIR/.zsh_history"
export DISABLE_AUTO_TITLE="true"
export COMPLETION_WAITING_DOTS="true"

# ===== Tool Config =====
export HOMEBREW_NO_ENV_HINTS=1
export BAT_THEME="Monokai Extended"
export BAT_STYLE="full"
export BAT_PAGER="less -RF"
export MCP_DEBUG=false
export NODE_OPTIONS="--max-old-space-size=16384"

# ===== Language Runtimes =====
export PYENV_ROOT="$HOME/.pyenv"
export NVM_DIR="$HOME/.nvm"
export NVM_LAZY_LOAD=true
export PNPM_HOME="$HOME/Library/pnpm"

# PHP (Herd)
export HERD_PHP_82_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/82/"
export HERD_PHP_84_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/84/"

# ===== PATH (consolidated, no duplicates) =====
typeset -U path  # Ensures uniqueness

# Homebrew first (sets HOMEBREW_PREFIX)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Build PATH array - order matters (first = highest priority)
path=(
  "$HOME/.local/bin"
  "$HOME/.config/scripts"
  "$HOME/.claude/local"
  "$HOME/.claude-mod/bin"
  "$HOME/.amp/bin"
  "$HOME/.atuin/bin"
  "$HOME/.codeium/windsurf/bin"
  "$HOME/ai-stuff/bin"
  "$PNPM_HOME"
  "$HOME/.npm-global/bin"
  "$HOME/go/bin"
  "$PYENV_ROOT/bin"
  "$HOME/Library/Python/3.13/bin"
  "/Library/Frameworks/Python.framework/Versions/3.13/bin"
  "$HOMEBREW_PREFIX/opt/lua-language-server/bin"
  "$HOME/Library/Application Support/Herd/bin"
  $path
)

# ===== Runtime Initializers =====
# These spawn subshells but only run once per login

# Cargo/Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Pyenv
command -v pyenv &>/dev/null && eval "$(pyenv init -)"

# Rbenv
command -v rbenv &>/dev/null && eval "$(rbenv init -)"

# Luarocks
command -v luarocks &>/dev/null && eval "$(luarocks path --bin)"

# ===== Private Environment =====
[[ -f "$ZDOTDIR/.zprofile.private" ]] && source "$ZDOTDIR/.zprofile.private"

# ===== External Integrations =====
# OrbStack
[[ -f ~/.orbstack/shell/init.zsh ]] && source ~/.orbstack/shell/init.zsh

# Herd injected PHP binary (from installer)
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"
