#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting up Vim..."

# install vim if missing
if command -v apt >/dev/null; then
if ! command -v vim >/dev/null; then
sudo apt update
sudo apt install -y vim
fi
fi

# install vim-plug
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
echo "Installing vim-plug..."
curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs 
https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# link vimrc
ln -sf "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"

# install plugins
vim +'PlugInstall --sync' +qa

echo "Vim configured."
