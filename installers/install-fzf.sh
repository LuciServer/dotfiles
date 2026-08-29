#!/usr/bin/env bash
set -euo pipefail

USER_HOME="${HOME:-$(getent passwd "$USER" | cut -d: -f6)}"

echo "────────────────────────────────────────"
echo "Installing fzf"
echo "────────────────────────────────────────"

if [ ! -d "$USER_HOME/.fzf" ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git "$USER_HOME/.fzf"
  "$USER_HOME/.fzf/install" --all
else
  echo "fzf already installed"
fi
