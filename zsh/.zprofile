# ===== Environment Variables =====
export XDG_CONFIG_HOME="$HOME/.config"
export GOKU_EDN_CONFIG_FILE="$XDG_CONFIG_HOME/karabiner/karabiner.edn"
export LANG=en_US.UTF-8
export EDITOR=/opt/homebrew/bin/nvim
export HOMEBREW_NO_ENV_HINTS=1
export IDEAVIM_RC="$HOME/.config/ideavim/.ideavimrc"

# ===== Path Management =====
typeset -U path_dirs
path_dirs=(
  "/opt/homebrew/bin"
  "$HOME/Library/pnpm"
  "$HOME/Library/Application Support/Herd/bin/"
  "$HOME/.config/scripts/"
  "$HOME/.atuin/bin"
  "$PATH"
)
export PATH=${(j.:.)path_dirs}
  
# Homebrew path (calculate once)
eval "$(/opt/homebrew/bin/brew shellenv)"

# ===== Language Environment Setup =====
 
# PHP (Herd)
export HERD_PHP_82_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/82/"
export HERD_PHP_84_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/84/"

# PNPM
export PNPM_HOME="$HOME/Library/pnpm"

# Ruby environment
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# Lua environment
eval "$(luarocks path --bin)"

