# ===== WezTerm Config Protection =====
# Claude Code login creates ~/.wezterm.lua which overrides stow-managed config
[[ -f ~/.wezterm.lua ]] && rm -f ~/.wezterm.lua

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

# envman
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# FZF
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'
source <(fzf --zsh)

# Homebrew prefix (calculate once)
BREW_PREFIX=$HOMEBREW_PREFIX

# Zsh plugins
source $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# https://github.com/jeffreytse/zsh-vi-mode?tab=readme-ov-file#custom-escape-key
source $BREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# Atuin (shell history)
eval "$(atuin init zsh)"
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
 

# Auto-switch Node version based on .nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
  # Check if nvm is loaded before trying to use it
  if ! command -v nvm_find_nvmrc &> /dev/null; then
    return
  fi
  
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

# Only call load-nvmrc if nvm is already loaded
if command -v nvm_find_nvmrc &> /dev/null; then
  load-nvmrc
fi

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
alias gl='git log --oneline --graph --decorate'
alias gu='git reset --soft HEAD~1' # undo last commit, but keep changes
alias guh='git reset --hard HEAD~1' # undo last commit, and lose changes
alias lg='lazygit'
alias nv="nvim ."
alias sz="source ~/.config/zsh/.zshrc"
alias sp="source ~/.config/zsh/.zprofile"

# HTTP requests
alias http="xh"

# Shopify
alias h2='$(npm prefix -s)/node_modules/.bin/shopify hydrogen'

# Force jq to always use colors, even when outputting to a pipe
alias jq='jq -C'

# Claude Code
# alias claude="/Users/kevin/.claude/local/claude"
alias cc='claude'
alias ccp='claude -p'
alias ccc='claude --continue'
alias ccy='claude --dangerously-skip-permissions'
alias ccyc='claude --dangerously-skip-permissions --continue'
alias claude-mod='~/.claude-mod/bin/claude-mod'
alias cm='~/.claude-mod/bin/claude-mod'

# Python
alias python=python3
alias pip=pip3

# Docker
alias docker-compose='docker compose'

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

# Superfile file manager with directory tracking
function yy() {
	export SPF_LAST_DIR="$HOME/Library/Application Support/superfile/lastdir"
	command spf "$@"
	[ ! -f "$SPF_LAST_DIR" ] || {
		. "$SPF_LAST_DIR"
		rm -f -- "$SPF_LAST_DIR" > /dev/null
	}
}

# Directory navigation helpers
cx() { cd "$@" && l; }
fcd() { cd "$(find . -type d -not -path '*/.*' | fzf)" && l; }
f() { echo "$(find . -type f -not -path '*/.*' | fzf)" | pbcopy }
fv() { nvim "$(find . -type f -not -path '~/.config/.*' | fzf)" }

# ===== zsh-vi-mode custom bindings =====
 
# Zoxide interactive search widget
zi-widget() {
  BUFFER="zi"
  zle accept-line
}
zle -N zi-widget 

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
  bindkey '^o' zi-widget
}

# When brew install, update, upgrade, or uninstall are run, update the Brewfile
# commit, and push the changes.
function brew() {
    # Store current directory
    local current_dir=$(pwd)
    
    #Run the original brew command
    command brew "$@"
    local brew_exit_code=$?
    
    # Only proceed if brew command was successful
    if [[ $brew_exit_code -eq 0 ]]; then
        if [[ "$1" == "install" || "$1" == "update" || "$1" == "upgrade" || "$1" == "uninstall" ]]; then
            echo "Updating Brewfile in dotfiles repository..."
            
            # Change to dotfiles directory
            cd ~/dotfiles
            
            # Update Brewfile
            command brew bundle dump --file=~/dotfiles/homebrew/Brewfile --force
            
            # Add to git
            git add homebrew/Brewfile
            
            # Commit and push if there are changes
            if git diff --cached --quiet homebrew/Brewfile; then
                echo "No changes in Brewfile"
            else
                git commit -m "Update Brewfile with new Homebrew changes"
                git push && echo "Brewfile updated and pushed to repository"
            fi
            
            # Return to original directory
            cd "$current_dir"
        fi
    fi
    
    # Return the original brew command's exit code
    return $brew_exit_code
}

. "$HOME/.local/bin/env"

# claude-mod PATH
export PATH="$HOME/.claude-mod/bin:$PATH"

# Claude-mod environment variables
export CLAUDE_MOD_ENV_DIR="$HOME/.claude-mod"
export CLAUDE_MOD_MCP_DIR="$HOME/.claude-mod/mcp"

# Amp CLI
export PATH="$HOME/.amp/bin:$PATH"

# direnv - load environment from .envrc files
eval "$(direnv hook zsh)"
