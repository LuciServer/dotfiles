#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up SSH..."

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

ln -sf "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

echo "SSH config installed."
