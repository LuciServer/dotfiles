#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_HOME="$HOME"

echo "────────────────────────────────────────"
echo "Installing Zsh environment"
echo "User: $USER"
echo "Home: $USER_HOME"
echo "Dotfiles: $DOTFILES_DIR"
echo "────────────────────────────────────────"

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

# Install dependencies
if command -v apt >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y zsh git curl
elif [ "$(uname -s)" = "Darwin" ]; then
  ensure_homebrew
  brew install zsh git curl
else
  echo "Error: Unable to install Zsh dependencies automatically on this operating system."
  exit 1
fi

# Install Oh My Zsh
if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}"

mkdir -p "$ZSH_CUSTOM/plugins"
mkdir -p "$ZSH_CUSTOM/themes"

# Install plugins
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "Installing zsh-autosuggestions..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "Installing zsh-syntax-highlighting..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Install Powerlevel10k
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  echo "Installing powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# Install configuration files
echo "Installing Zsh configuration..."

# Remove broken symlinks if they exist
[ -L "$USER_HOME/.zshrc" ] && rm "$USER_HOME/.zshrc"
[ -L "$USER_HOME/.p10k.zsh" ] && rm "$USER_HOME/.p10k.zsh"
[ -L "$USER_HOME/.zsh_custom" ] && rm "$USER_HOME/.zsh_custom"

# Copy configuration
cp "$DOTFILES_DIR/zsh/.zshrc" "$USER_HOME/.zshrc"

if [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]; then
  cp "$DOTFILES_DIR/zsh/.p10k.zsh" "$USER_HOME/.p10k.zsh"
fi

if [ -f "$DOTFILES_DIR/zsh/.zsh_custom" ]; then
  cp "$DOTFILES_DIR/zsh/.zsh_custom" "$USER_HOME/.zsh_custom"
fi

if [ -d "$DOTFILES_DIR/zsh-utils" ]; then
  rm -rf "$USER_HOME/.zsh-utils"
  cp -r "$DOTFILES_DIR/zsh-utils" "$USER_HOME/.zsh-utils"
fi

# Set default shell
ZSH_BIN="$(command -v zsh)"

if ! grep -qx "$ZSH_BIN" /etc/shells; then
  echo "Adding $ZSH_BIN to /etc/shells"
  echo "$ZSH_BIN" | sudo tee -a /etc/shells > /dev/null
fi

if [ "${SHELL:-}" != "$ZSH_BIN" ]; then
  echo "Setting default shell to zsh..."
  chsh -s "$ZSH_BIN" "$USER"
fi

echo ""
echo "────────────────────────────────────────"
echo "Zsh installation complete."
echo "────────────────────────────────────────"
echo ""
echo "Start a new shell:"
echo ""
echo "    exec zsh"
echo ""
echo "If you want to generate a Powerlevel10k prompt configuration:"
echo ""
echo "    p10k configure"
echo ""
echo "This will create ~/.p10k.zsh if it does not exist."
echo ""
