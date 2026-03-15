#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting up Git..."

# Install git if missing
if command -v apt >/dev/null; then
  if ! command -v git >/dev/null; then
    sudo apt update
    sudo apt install -y git
  fi
fi

# Link gitconfig
ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

echo "Cleaning malformed Git URL rewrites..."

git config --global --unset-all url.git@github.com:.insteadOf 2>/dev/null || true
git config --global --unset-all url.git@gitlab.com:.insteadOf 2>/dev/null || true

echo "Applying SSH rewrite rules..."

git config --global url."git@github.com:".insteadOf https://github.com/
git config --global url."git@gitlab.com:".insteadOf https://gitlab.com/

echo "Git configured."