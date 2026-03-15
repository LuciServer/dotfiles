#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up Vim..."

# Install vim
if command -v brew >/dev/null; then
if ! command -v vim >/dev/null; then
brew install vim
fi
fi

if command -v apt >/dev/null; then
if ! command -v vim >/dev/null; then
sudo apt update
sudo apt install -y vim
fi
fi

# Install vim-plug if missing
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
curl -fLo ~/.vim/autoload/plug.vim --create-dirs 
https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Link vimrc
ln -sf "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"

# Install plugins
vim +PlugInstall +qall

echo "Vim configured."
