#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting up SSH..."

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# remove broken symlink if exists
rm -f "$HOME/.ssh/config"

# create symlink
ln -s "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"

# correct permissions
chmod 600 "$DOTFILES_DIR/ssh/config"

echo "SSH configured."
