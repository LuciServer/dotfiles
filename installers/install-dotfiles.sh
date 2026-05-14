#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Installing dotfiles..."

bash "$DOTFILES_DIR/installers/install-ssh.sh"
bash "$DOTFILES_DIR/installers/install-gpg.sh"
bash "$DOTFILES_DIR/installers/install-git.sh"
bash "$DOTFILES_DIR/installers/install-vim.sh"
bash "$DOTFILES_DIR/installers/install-zsh.sh"

latest_gpg_instructions="$(ls -t "$DOTFILES_DIR"/output/gpg/*/instructions.txt 2>/dev/null | head -n 1 || true)"

if [ -n "$latest_gpg_instructions" ]; then
  echo ""
  echo "Open the GPG setup instructions here:"
  echo ""
  echo "    $latest_gpg_instructions"
fi

echo "Dotfiles installation completed."
