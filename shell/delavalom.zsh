# Delavalom Stack — ZSH Configuration
# Source this from your .zshrc: source /path/to/delavalom-stack/shell/delavalom.zsh
# Or install via: bash install.sh --full (adds source line to .zshrc)

# ============================================================
# Mise — Single tool manager for ALL language runtimes
# https://mise.jdx.dev
# Manages: node, python, go, rust, bun, java, and more
# ============================================================
if [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
elif command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# Go bin path (mise sets GOPATH, we just need bin on PATH)
[[ -n "$GOPATH" ]] && [[ ":$PATH:" != *":$GOPATH/bin:"* ]] && export PATH="$PATH:$GOPATH/bin"

# ============================================================
# Starship Prompt (gruvbox dark theme)
# ============================================================
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# ============================================================
# ZSH Autosuggestions
# ============================================================
if [ -f "$(brew --prefix 2>/dev/null)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [ -f "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# ============================================================
# ZSH Syntax Highlighting (if installed)
# ============================================================
if [ -f "$(brew --prefix 2>/dev/null)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [ -f "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# ============================================================
# Dev Aliases
# ============================================================

# Claude Code shortcuts
alias cc="claude"
alias ccc="claude --continue"
alias ccp="claude --permission-mode plan"

# Git shortcuts
alias gs="git status"
alias gd="git diff"
alias gl="git log --oneline -20"
alias gp="git pull"
alias gc="git commit"
alias gco="git checkout"
alias gb="git branch"

# Docker
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcl="docker compose logs -f"

# Kubernetes
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get svc"
alias kgd="kubectl get deploy"
alias kl="kubectl logs -f"
alias kx="kubectl exec -it"

# Mise shortcuts
alias mi="mise install"
alias mu="mise use"
alias ml="mise list"
alias mr="mise run"

# Dev cleanup
alias nukedev="rm -rf ~/Library/Developer/Xcode/DerivedData/* && rm -rf ~/.gradle/caches/ && xcrun simctl delete unavailable 2>/dev/null"
alias nukebuild="rm -rf node_modules .next dist build out .turbo .cache"
alias nukedocker="docker system prune -af --volumes"

# Quick navigation
alias dev="cd ~/delavalom-labs"
alias stack="cd ~/delavalom-labs/delavalom-stack"

# ============================================================
# Completions
# ============================================================

# Bun completions (mise installs bun, but completions are separate)
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# kubectl completions
if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh 2>/dev/null)
fi

# mise completions
if command -v mise &>/dev/null; then
  eval "$(mise completion zsh 2>/dev/null)"
fi

# ============================================================
# History
# ============================================================
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
