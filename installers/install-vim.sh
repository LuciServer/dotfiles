#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting up Vim..."

load_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    return 0
  fi

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return 0
  fi

  if [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    return 0
  fi

  return 1
}

ensure_homebrew() {
  if load_homebrew; then
    return 0
  fi

  if [ "$(uname -s)" != "Darwin" ]; then
    return 1
  fi

  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew
}

if ! command -v vim >/dev/null 2>&1; then
  if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y vim curl git
  elif [ "$(uname -s)" = "Darwin" ]; then
    ensure_homebrew
    brew install vim
  else
    echo "Error: Unable to install Vim automatically on this operating system."
    exit 1
  fi
fi

# Install Node.js (required for coc.nvim)
if ! command -v node >/dev/null 2>&1; then
  echo "Installing Node.js for coc.nvim..."

  if command -v apt >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
  elif [ "$(uname -s)" = "Darwin" ]; then
    ensure_homebrew
    brew install node
  else
    echo "Error: Unable to install Node.js automatically on this operating system."
    exit 1
  fi
fi

# Install vim-plug plugin manager
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  echo "Installing vim-plug..."
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Link vim configuration
ln -sf "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"

# Install plugins
echo "Installing Vim plugins..."
vim +'PlugInstall --sync' +qa

echo "Vim configured successfully."
