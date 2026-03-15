#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up Git..."

# Install Git (macOS)
if command -v brew >/dev/null; then
if ! command -v git >/dev/null; then
brew install git
fi
fi

# Install Git (Ubuntu/Debian)
if command -v apt >/dev/null; then
if ! command -v git >/dev/null; then
sudo apt update
sudo apt install -y git
fi
fi

ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

echo "Git configured."
