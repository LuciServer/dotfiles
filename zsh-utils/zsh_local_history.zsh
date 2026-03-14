#!/usr/bin/env zsh

LOCAL_HIST_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh_per_dir_history"
mkdir -p "$LOCAL_HIST_DIR"

_switch_to_dir_history() {
  local dir_slug="${PWD//\//%}"
  fc -p "$LOCAL_HIST_DIR/$dir_slug"
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _switch_to_dir_history

_switch_to_dir_history

alias globalhist='fc -P'
