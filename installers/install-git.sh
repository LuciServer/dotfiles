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

echo "Checking SSH connectivity to GitHub..."

if ssh -T [git@github.com](mailto:git@github.com) 2>&1 | grep -q "successfully authenticated"; then
echo "SSH works. Enabling SSH URL rewrites..."

git config --global url."[git@github.com](mailto:git@github.com):".insteadOf https://github.com/
git config --global url."[git@gitlab.com](mailto:git@gitlab.com):".insteadOf https://gitlab.com/

else
echo "SSH not configured yet. Skipping URL rewrite."
fi

echo "Git configured."
