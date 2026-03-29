#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting up Git..."

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

if ! command -v git >/dev/null 2>&1; then
  if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y git
  elif [ "$(uname -s)" = "Darwin" ]; then
    ensure_homebrew
    brew install git
  else
    echo "Error: Unable to install Git automatically on this operating system."
    exit 1
  fi
fi

# Link gitconfig
ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

echo "Cleaning malformed Git URL rewrites..."

git config --global --unset-all url.git@github.com:.insteadOf 2>/dev/null || true
git config --global --unset-all url.git@gitlab.com:.insteadOf 2>/dev/null || true

echo "Applying SSH rewrite rules..."

git config --global url."git@github.com:".insteadOf https://github.com/
git config --global url."git@gitlab.com:".insteadOf https://gitlab.com/

echo "Git configured."
