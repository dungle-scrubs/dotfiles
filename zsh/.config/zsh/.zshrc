export XDG_CONFIG_HOME="$HOME/.config"
export GOKU_EDN_CONFIG_FILE="$HOME/.config/karabiner/karabiner.edn"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export TERM="alacritty"

# Completion
# Reevaluate the prompt string each time it's displaying a prompt
setopt prompt_subst
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

source <(fzf --zsh)

# History setup  
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVESIZE=10000
setopt appendhistory
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

eval "$(atuin init zsh)"
. "$HOME/.atuin/bin/env"
export ATUIN_NOBIND="true"

bindkey '^r' atuin-search
# bindkey '^[[A' atuin-up-search
# bindkey '^[OA' atuin-up-search

bindkey '^k' atuin-up-search
bindkey '^j' atuin-down-search
# bindkey '^k' history-search-backward
# bindkey '^j' history-search-forward
bindkey '^w' autosuggest-execute
bindkey '^e' autosuggest-accept
bindkey '^u' autosuggest-toggle
bindkey '^L' vi-forward-word

# omz settings
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7
zstyle ':omz:plugins:nvm' silent-autoload yes

# Load plugins
plugins=(vscode zsh-nvm)

#Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Other Zsh settings
DISABLE_AUTO_TITLE="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="dd.mm.yyy"

#
export HAMMERSPOON_HOME=~/.config/hammerspoon#

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# homebrew
export EDITOR=/opt/homebrew/bin/nvim
export HOMEBREW_NO_ENV_HINTS=1

alias la=tree
alias cat=bat

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

# Docker
alias dco="docker compose"
alias dps="docker ps"
alias dpa="docker ps -a"
alias dl="docker ps -l -q"
alias dx="docker exec -it"

# Dirs
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

# HTTP requests with xh!
alias http="xh"

# VI Mode!!!
bindkey '\e' vi-cmd-mode
# enable vim keybindings
bindkey -v

# Eza
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"

function ranger {
	local IFS=$'\t\n'
	local tempfile="$(mktemp -t tmp.XXXXXX)"
	local ranger_cmd=(
		command
		ranger
		--cmd="map Q chain shell echo %d > "$tempfile"; quitall"
	)

	${ranger_cmd[@]} "$@"
	if [[ -f "$tempfile" ]] && [[ "$(cat -- "$tempfile")" != "$(echo -n `pwd`)" ]]; then
		cd -- "$(cat "$tempfile")" || return
	fi
	command rm -f -- "$tempfile" 2>/dev/null
}
alias rr='ranger'

# node version manager
export NVM_LAZY_LOAD=true
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

## update node verrsion from .nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
      # nvm install --silent
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use --silent
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    nvm use default --silent
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# alias
alias btm="btm --left_legend --mem_as_value"
# alias ls="eza --long --all --color-scale --git --header --icons=always --group-directories-first --total-size"
alias ls="eza --icons=always --group-directories-first --color=auto"

# pnpm
export PNPM_HOME="/Users/kevin/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# herd
export PATH="/Users/kevin/Library/Application Support/Herd/bin/":$PATH
## injected PHP 8.2 configuration.
export HERD_PHP_82_INI_SCAN_DIR="/Users/kevin/Library/Application Support/Herd/config/php/82/"

# Starship
eval "$(starship init zsh)"
export STARSHIP_CONFIG=$HOME/.config/starship/starship.toml

# fzf
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ruby version manager
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# tabtab source for electron-forge package
# uninstall by removing these lines or running `tabtab uninstall electron-forge`
[[ -f /Users/kevin/Library/pnpm/store/v3/tmp/dlx-87268/node_modules/.pnpm/tabtab@2.2.2/node_modules/tabtab/.completions/electron-forge.zsh ]] && . /Users/kevin/Library/pnpm/store/v3/tmp/dlx-87268/node_modules/.pnpm/tabtab@2.2.2/node_modules/tabtab/.completions/electron-forge.zsh

# shopify hydrogen alias to local projects
alias h2='$(npm prefix -s)/node_modules/.bin/shopify hydrogen'

# tmux
export PATH="$HOME/.config/tmux/plugins/tmuxifier/bin":$PATH
eval "$(tmuxifier init -)"
 
#lua
eval "$(luarocks path --bin)"
export PATH="/usr/local/bin:$PATH"

# zellij
alias zj="zellij"

#vim
alias vim="vim -u $HOME/.config/vim/vimrc"

# nvim version switcher
alias nvim_old="NVIM_APPNAME=nvim_old nvim"
alias kickstart="NVIM_APPNAME=kickstart nvim"
alias nvchad="NVIM_APPNAME=nvchad nvim"
alias astrovim="NVIM_APPNAME=astrovim nvim"
alias freshvim="NVIM_APPNAME=freshvim nvim"

function nvims() {
  items=("default" "kickstart" "nvim_old" "nvchad" "astrovim" "freshvim")
  config=$(printf "%s\n" "${items[@]}" | fzf --prompt=" Neovim Config  " --height=~50% --layout=reverse --border --exit-0)
  if [[ -z $config ]]; then
    echo "Nothing selected"
    return 0
  elif [[ $config == "default" ]]; then
    config=""
  fi
  NVIM_APPNAME=$config nvim $@
}

bindkey -s ^a "nvims\n"

# my scripts
export PATH="/Users/kevin/dotfiles/scripts/":$PATH 

# navigation
cx() { cd "$@" && l; }
fcd() { cd "$(find . -type d -not -path '*/.*' | fzf)" && l; }
f() { echo "$(find . -type f -not -path '*/.*' | fzf)" | pbcopy }
fv() { nvim "$(find . -type f -not -path '~/.config/.*' | fzf)" }

# zoxide
eval "$(zoxide init zsh)"

export ESLINT_USE_FLAT_CONFIG=false

