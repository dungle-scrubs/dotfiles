# ===== Completion System =====
autoload -Uz compinit
# Only regenerate .zcompdump once per day
if [[ -n ~/.config/zsh/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

setopt prompt_subst
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# ===== Zsh Plugins (from Homebrew) =====
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOMEBREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# ===== Tool Integrations =====
# Use cached init files when available, fall back to eval

# FZF
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'
source <(fzf --zsh)

# Atuin (shell history) - cached
if [[ -f "$ZDOTDIR/cache/atuin.zsh" ]]; then
  source "$ZDOTDIR/cache/atuin.zsh"
else
  eval "$(atuin init zsh)"
fi

# Zoxide - cached
if [[ -f "$ZDOTDIR/cache/zoxide.zsh" ]]; then
  source "$ZDOTDIR/cache/zoxide.zsh"
else
  eval "$(zoxide init zsh)"
fi

# Starship prompt - cached
# Fix for zsh-vi-mode conflict: https://github.com/starship/starship/issues/3418
if [[ "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select" || \
      "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select-wrapped" ]]; then
  zle -N zle-keymap-select ""
fi
if [[ -f "$ZDOTDIR/cache/starship.zsh" ]]; then
  source "$ZDOTDIR/cache/starship.zsh"
else
  eval "$(starship init zsh)"
fi

# Navi (cheatsheets)
eval "$(navi widget zsh)"

# Direnv
eval "$(direnv hook zsh)"

# ===== NVM (lazy loaded) =====
# Load nvm on first use
nvm() {
  unset -f nvm node npm npx
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  nvm "$@"
}
node() { nvm --version &>/dev/null; unset -f node; node "$@"; }
npm() { nvm --version &>/dev/null; unset -f npm; npm "$@"; }
npx() { nvm --version &>/dev/null; unset -f npx; npx "$@"; }

# Auto-switch Node version on directory change
autoload -U add-zsh-hook
load-nvmrc() {
  # Skip if nvm not loaded yet
  [[ -z "$NVM_DIR" ]] && return
  [[ ! -s "$NVM_DIR/nvm.sh" ]] && return

  # Only load nvm if .nvmrc exists
  local nvmrc_path="$(pwd)/.nvmrc"
  [[ ! -f "$nvmrc_path" ]] && nvmrc_path="$(pwd)/.node-version"

  if [[ -f "$nvmrc_path" ]]; then
    # Force load nvm if needed
    if ! command -v nvm_find_nvmrc &>/dev/null; then
      source "$NVM_DIR/nvm.sh"
    fi

    local nvmrc_node_version=$(nvm version "$(cat "$nvmrc_path")")
    if [[ "$nvmrc_node_version" = "N/A" ]]; then
      nvm install
    elif [[ "$nvmrc_node_version" != "$(nvm version)" ]]; then
      nvm use --silent
    fi
  fi
}
add-zsh-hook chpwd load-nvmrc

# Auto-switch Claude credentials based on directory
load-claude-config() {
  local config_file="$HOME/.config/claude-work-dirs"
  [[ ! -f "$config_file" ]] && { unset CLAUDE_CONFIG_DIR; return; }

  local line dir config_dir
  while IFS=: read -r dir config_dir; do
    [[ -z "$dir" || "$dir" == \#* ]] && continue
    if [[ "$PWD" == "$dir"* ]]; then
      export CLAUDE_CONFIG_DIR="$config_dir"
      return
    fi
  done < "$config_file"

  unset CLAUDE_CONFIG_DIR
}
add-zsh-hook chpwd load-claude-config
load-claude-config  # Run on shell start

# ===== Aliases =====

# File listing
alias la=tree
alias cat=bat
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias ltree="eza --tree --level=2 --icons --git"

# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

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
alias gu='git reset --soft HEAD~1'
alias guh='git reset --hard HEAD~1'
alias lg='lazygit'

# Editor
alias nv="nvim ."
alias sz="source $ZDOTDIR/.zshrc"
alias sp="source $ZDOTDIR/.zprofile"

# HTTP
alias http="xh"
alias jq='jq -C'

# Shopify
alias h2='$(npm prefix -s)/node_modules/.bin/shopify hydrogen'

# Claude Code
alias cc='claude'
alias ccp='claude -p'
alias ccc='claude --continue'
alias ccy='claude --dangerously-skip-permissions'
alias ccyc='claude --dangerously-skip-permissions --continue'
alias cm='claude-mod'

# Codex
alias co='codex'
alias coy='codex --yolo'
alias coyc='codex resume --last --yolo'

# Python
alias python=python3
alias pip=pip3

# Docker
alias docker-compose='docker compose'

# ===== Functions =====

# Yazi with directory tracking
y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" ]] && [[ "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# cd + list
cx() { cd "$@" && l; }

# Fuzzy directory navigation
fcd() { cd "$(find . -type d -not -path '*/.*' | fzf)" && l; }

# Fuzzy file copy to clipboard
f() { echo "$(find . -type f -not -path '*/.*' | fzf)" | pbcopy; }

# Fuzzy file open in nvim
fv() { nvim "$(find . -type f -not -path '*/.*' | fzf)"; }

# Regenerate cached init files
zsh-cache-rebuild() {
  local cache_dir="$ZDOTDIR/cache"
  mkdir -p "$cache_dir"

  echo "Rebuilding zsh init cache..."
  atuin init zsh > "$cache_dir/atuin.zsh"
  zoxide init zsh > "$cache_dir/zoxide.zsh"
  starship init zsh > "$cache_dir/starship.zsh"
  echo "Done. Restart shell to use cached files."
}

# ===== Vi-mode Keybindings =====

# Zoxide interactive widget
zi-widget() {
  BUFFER="zi"
  zle accept-line
}
zle -N zi-widget

# Runs after zsh-vi-mode initializes (rebind keys it clobbers)
zvm_after_init() {
  # Atuin
  bindkey '^r' atuin-search
  bindkey '^[[A' atuin-up-search
  bindkey '^[OA' atuin-up-search

  # Autosuggestions
  bindkey '^w' autosuggest-execute
  bindkey '^e' autosuggest-accept
  bindkey '^u' autosuggest-toggle

  # Navigation
  bindkey '^L' vi-forward-word
  bindkey '^k' up-line-or-search
  bindkey '^j' down-line-or-search
  bindkey '^o' zi-widget
}

# ===== Completions =====
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
