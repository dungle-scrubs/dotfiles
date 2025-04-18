# ===== Environment Variables =====
export XDG_CONFIG_HOME="$HOME/.config"
export GOKU_EDN_CONFIG_FILE="$XDG_CONFIG_HOME/karabiner/karabiner.edn"
export LANG=en_US.UTF-8
export EDITOR=/opt/homebrew/bin/nvim
export HOMEBREW_NO_ENV_HINTS=1
export STARSHIP_CONFIG=$HOME/.config/starship/starship.toml
export DISABLE_AUTO_TITLE="true"
export COMPLETION_WAITING_DOTS="true"

# ===== Path Management =====
typeset -U path_dirs
path_dirs=(
  "/opt/homebrew/bin"
  "$HOME/Library/pnpm"
  "$HOME/Library/Application Support/Herd/bin/"
  "./scripts/"
  "$HOME/.atuin/bin"
  "$PATH"
)
export PATH=${(j.:.)path_dirs}

# ===== Oh My Zsh Configuration =====
export ZSH="$HOME/.oh-my-zsh"
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7
zstyle ':omz:plugins:nvm' silent-autoload yes
plugins=(vscode zsh-nvm)
source $ZSH/oh-my-zsh.sh

# ===== Completion Settings =====
setopt prompt_subst
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# ===== Tool Configuration =====
# FZF
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'
source <(fzf --zsh)

# Homebrew prefix (calculate once)
BREW_PREFIX=$(brew --prefix)

# Zsh plugins
source $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# https://github.com/jeffreytse/zsh-vi-mode?tab=readme-ov-file#custom-escape-key
source $BREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# Atuin (shell history)
eval "$(atuin init zsh)"
. "$HOME/.atuin/bin/env"
export ATUIN_NOBIND="true"

# Navi
eval "$(navi widget zsh)"

# Zoxide
eval "$(zoxide init zsh)"

# Starship prompt
# https://github.com/starship/starship/issues/3418#issuecomment-1711630970
if [[ "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select" || \
      "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select-wrapped" ]]; then
    zle -N zle-keymap-select "";
fi
eval "$(starship init zsh)"

# ===== Node.js Management =====
# NVM configuration
export NVM_LAZY_LOAD=true
export NVM_DIR="$HOME/.nvm"
# Uncomment if zsh-nvm plugin isn't working properly
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Auto-switch Node version based on .nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use --silent
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    nvm use default --silent
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# PNPM
export PNPM_HOME="$HOME/Library/pnpm"

# ===== Other Language Support =====
# Ruby
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# Lua
eval "$(luarocks path --bin)"

# PHP (Herd)
export HERD_PHP_82_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/82/"

# ===== Key Bindings =====

# Custom key bindings
# bindkey '^r' atuin-search
# bindkey '^w' autosuggest-execute
# bindkey '^e' autosuggest-accept
# bindkey '^u' autosuggest-toggle
# bindkey '^L' vi-forward-word
# bindkey '^k' up-line-or-search
# bindkey '^j' down-line-or-search

# Zoxide interactive search widget
zi-widget() {
  BUFFER="zi"
  zle accept-line
}
zle -N zi-widget 
# bindkey '^f' zi-widget

# ===== Aliases =====
# File listing
alias la=tree
alias cat=bat
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias ltree="eza --tree --level=2  --icons --git"

# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

# Git
alias gc="git commit -m"
alias gca="git commit -a -m"
alias gp="git push origin HEAD"
alias gpu="git pull origin"
alias gst="git status"
alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
alias gdiff="git diff"
alias gco="git checkout"
alias gb='git branch'
alias gba='git branch -a'
alias gadd='git add'
alias ga='git add -p'
alias gcoall='git checkout -- .'
alias gr='git remote'
alias gre='git reset'

# HTTP requests
alias http="xh"

# Shopify
alias h2='$(npm prefix -s)/node_modules/.bin/shopify hydrogen'

# ===== Custom Functions =====
# Yazi file manager with directory tracking
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Directory navigation helpers
cx() { cd "$@" && l; }
fcd() { cd "$(find . -type d -not -path '*/.*' | fzf)" && l; }
f() { echo "$(find . -type f -not -path '*/.*' | fzf)" | pbcopy }
fv() { nvim "$(find . -type f -not -path '~/.config/.*' | fzf)" }

# ===== Completion Sourcing =====
# Tabtab completions
[[ -f $HOME/Library/pnpm/store/v3/tmp/dlx-87268/node_modules/.pnpm/tabtab@2.2.2/node_modules/tabtab/.completions/electron-forge.zsh ]] && . $HOME/Library/pnpm/store/v3/tmp/dlx-87268/node_modules/.pnpm/tabtab@2.2.2/node_modules/tabtab/.completions/electron-forge.zsh

# ===== zsh-vi-mode custom bindings =====
# This function runs after zsh-vi-mode initializes
function zvm_after_init() {
  # Bind Ctrl+R to Atuin search
  bindkey '^r' atuin-search
  
  # Your other custom bindings
  bindkey '^w' autosuggest-execute
  bindkey '^e' autosuggest-accept
  bindkey '^u' autosuggest-toggle
  bindkey '^L' vi-forward-word
  bindkey '^k' up-line-or-search
  bindkey '^j' down-line-or-search
  
  # Zoxide widget binding
  bindkey '^f' zi-widget
}
