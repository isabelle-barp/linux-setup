# Example ~/.zshrc managed via GNU Stow (package: zsh)
# This file will be symlinked to $HOME/.zshrc by running:
#   bash scripts/80_dotfiles.sh zsh
# You can override anything in ~/.zshrc.local (auto-sourced if present).

# ----- Shell options -----
set -o noclobber
set -o notify
set -o correct
set -o interactivecomments

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_REDUCE_BLANKS EXTENDED_HISTORY

# Locale
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

# PATH
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# Editor
export EDITOR=${EDITOR:-vim}
export VISUAL=${VISUAL:-$EDITOR}

# Prompt: Starship (if installed)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Oh My Zsh (if installed)
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME="robbyrussell"
  plugins=(git z sudo)
  source "$ZSH/oh-my-zsh.sh"
fi

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# Docker cleanup convenience command
# Provides `docker-clean` function and `docker-nuke` alias.
# It prefers the installed symlink at ~/.local/bin/docker-nuke (created by scripts/20_user_scripts.sh),
# falls back to the repo script if available, and otherwise prints a helpful hint.
function docker-clean() {
  local BIN="$HOME/.local/bin/docker-nuke"
  if [[ -x "$BIN" ]]; then
    "$BIN" "$@"
    return $?
  fi
  local REPO_SCRIPT="$HOME/Source/Code/Personal/linux-setup/user-scripts/docker-clean-all.sh"
  if [[ -x "$REPO_SCRIPT" ]]; then
    "$REPO_SCRIPT" "$@"
    return $?
  fi
  echo "docker cleanup script not found. Tip: run 'bash scripts/20_user_scripts.sh' inside the repo to install it into ~/.local/bin." >&2
  return 127
}
# Backwards-compatible alias
alias docker-nuke='docker-clean'

# 1Password CLI → export AI API keys for Aider and others
# Customize via environment variables:
#   OP_VAULT (default: Private)
#   OP_ITEM_OPENAI (default: "OpenAI API Key") with field OP_FIELD_OPENAI (default: api_key)
#   OP_ITEM_ANTHROPIC (default: "Anthropic API Key") with field OP_FIELD_ANTHROPIC (default: api_key)
#   OP_ITEM_GEMINI (default: "Gemini API Key") with field OP_FIELD_GEMINI (default: api_key)
#   OP_ITEM_GROQ (default: "Groq API Key") with field OP_FIELD_GROQ (default: api_key)
# Usage:
#   aider-keys        # exports variables in current shell
#   aider-keys -q     # quiet output
function aider-keys() {
  local QUIET=0
  if [[ "${1:-}" == "-q" ]]; then QUIET=1; fi
  if ! command -v op >/dev/null 2>&1; then
    echo "op (1Password CLI) not found. Install and run: op signin" >&2
    return 1
  fi
  local VAULT="${OP_VAULT:-Private}"
  local OI_OPENAI="${OP_ITEM_OPENAI:-OpenAI API Key}"; local OF_OPENAI="${OP_FIELD_OPENAI:-api_key}"
  local OI_ANTHRO="${OP_ITEM_ANTHROPIC:-Anthropic API Key}"; local OF_ANTHRO="${OP_FIELD_ANTHROPIC:-api_key}"
  local OI_GEMINI="${OP_ITEM_GEMINI:-Gemini API Key}"; local OF_GEMINI="${OP_FIELD_GEMINI:-api_key}"
  local OI_GROQ="${OP_ITEM_GROQ:-Groq API Key}"; local OF_GROQ="${OP_FIELD_GROQ:-api_key}"
  # shellcheck disable=SC2155
  export OPENAI_API_KEY="$(op item get "$OI_OPENAI" --vault "$VAULT" --fields label="$OF_OPENAI" 2>/dev/null | tr -d '\r')"
  export ANTHROPIC_API_KEY="$(op item get "$OI_ANTHRO" --vault "$VAULT" --fields label="$OF_ANTHRO" 2>/dev/null | tr -d '\r')"
  export GEMINI_API_KEY="$(op item get "$OI_GEMINI" --vault "$VAULT" --fields label="$OF_GEMINI" 2>/dev/null | tr -d '\r')"
  export GROQ_API_KEY="$(op item get "$OI_GROQ" --vault "$VAULT" --fields label="$OF_GROQ" 2>/dev/null | tr -d '\r')"
  if (( QUIET == 0 )); then
    echo "Exported: OPENAI_API_KEY=${OPENAI_API_KEY:+✓} ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:+✓} GEMINI_API_KEY=${GEMINI_API_KEY:+✓} GROQ_API_KEY=${GROQ_API_KEY:+✓}"
  fi
}

# Node Version Manager (NVM)
# Initializes NVM if installed via ~/.nvm, system package (/usr/share/nvm), or Homebrew
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # Standard user install
  source "$NVM_DIR/nvm.sh"
elif [ -s "/usr/share/nvm/init-nvm.sh" ]; then
  # Some distros package an init script here
  source "/usr/share/nvm/init-nvm.sh"
elif command -v brew >/dev/null 2>&1 && [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ]; then
  # Homebrew (macOS/Linuxbrew)
  export NVM_DIR="$HOME/.nvm"
  source "$(brew --prefix)/opt/nvm/nvm.sh"
fi
# Optional: tab completion for nvm
if [ -s "$NVM_DIR/bash_completion" ]; then
  source "$NVM_DIR/bash_completion"
fi

# Load user overrides if present
if [[ -f "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi

export GTK_THEME=WhiteSur-Light
export XDG_CURRENT_DESKTOP=i3
export GTK_APPLICATION_PREFER_DARK_THEME=0
export CHROME_FORCE_DARK_MODE=0
# Improve Java (JetBrains) window behavior under i3
export _JAVA_AWT_WM_NONREPARENTING=1
export ZSH="/root/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
