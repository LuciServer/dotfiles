#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Installing dotfiles..."

bash "$DOTFILES_DIR/installers/install-ssh.sh"
bash "$DOTFILES_DIR/installers/install-gpg.sh"
bash "$DOTFILES_DIR/installers/install-git.sh"
bash "$DOTFILES_DIR/installers/install-vim.sh"
bash "$DOTFILES_DIR/installers/install-zsh.sh"

echo "Dotfiles installation completed."
