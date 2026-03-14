# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Powerlevel10k config
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Plugin config
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#939393,bold,underline"

# Environment
export NVM_DIR="$HOME/.nvm"
export OLLAMA_HOST="http://localhost:11434"
export GPG_TTY=$(tty)

# Paths
export PATH="$HOME/.console-ninja/.bin:$PATH"

# Load tools
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"
[ -f "$HOME/.zsh_custom" ] && source "$HOME/.zsh_custom"

# Monitoring
alias start_monitoring='cd ~/monitoring-stack && docker compose up --build -d'

# Docker
alias restart_docker='docker restart $(docker ps -q)'
alias stop_all_docker_containers='docker stop $(docker ps -a -q)'
alias remove_all_docker_containers='docker rm $(docker ps -a -q)'
alias restart_all_docker_containers='docker restart $(docker ps -q)'

# History controls
alias history-off='unsetopt INC_APPEND_HISTORY SHARE_HISTORY; export HISTFILE='
alias history-on='export HISTFILE="$HOME/.zsh_history"; setopt INC_APPEND_HISTORY SHARE_HISTORY'
