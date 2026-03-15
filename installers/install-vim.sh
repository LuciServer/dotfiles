#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting up Vim..."

# Install Vim if missing
if command -v apt >/dev/null; then
if ! command -v vim >/dev/null; then
sudo apt update
sudo apt install -y vim
fi
fi

# Install vim-plug plugin manager
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
echo "Installing vim-plug..."
curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Link vim config
ln -sf "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"

# Install plugins
vim +'PlugInstall --sync' +qa

echo "Vim configured."
