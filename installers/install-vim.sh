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
  elif load_homebrew || [ "$(uname -s)" = "Darwin" ]; then
    ensure_homebrew
    brew install vim
  else
    echo "ERROR: Cannot install vim — no supported package manager found (apt/brew)." >&2
    exit 1
  fi
fi

# Node.js (required for coc.nvim)
if ! command -v node >/dev/null 2>&1; then
  echo "Installing Node.js for coc.nvim..."
  if command -v apt >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
  elif load_homebrew || [ "$(uname -s)" = "Darwin" ]; then
    ensure_homebrew
    brew install node
  else
    echo "ERROR: Cannot install Node.js — no supported package manager found (apt/brew)." >&2
    exit 1
  fi
fi

if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  echo "Installing vim-plug..."
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

ln -sf "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"

# Install plugins (headless — works without a TTY, safe in CI)
echo "Installing Vim plugins..."
vim -Es -u "$HOME/.vimrc" +'PlugInstall --sync' +qa 2>/dev/null || true

echo "Vim configured successfully."
