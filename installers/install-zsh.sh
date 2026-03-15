#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_UTILS_DIR="$HOME/.zsh-utils"
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

echo "Starting Zsh environment setup..."

# Detect OS
OS="$(uname)"

# Install dependencies (Linux only)
if [ "$OS" = "Linux" ]; then
if command -v apt >/dev/null; then
echo "Installing required packages..."
sudo apt update
sudo apt install -y zsh git curl
fi
fi

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
echo "Installing Oh My Zsh..."
RUNZSH=no CHSH=no sh -c 
"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install Powerlevel10k
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"

if [ ! -d "$P10K_DIR" ]; then
echo "Installing Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# Install Zsh Plugins
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
echo "Installing zsh-autosuggestions..."
git clone https://github.com/zsh-users/zsh-autosuggestions 
"$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
echo "Installing zsh-syntax-highlighting..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting 
"$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Create XDG directories
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/state"
mkdir -p "$HOME/.local/share"

# Install Zsh utilities
echo "Installing zsh utilities..."

mkdir -p "$ZSH_UTILS_DIR"

cp -f "$DOTFILES_DIR/zsh-utils/"* "$ZSH_UTILS_DIR/" || true

chmod +x "$ZSH_UTILS_DIR/"* || true

# Symlink Zsh configuration
echo "Linking Zsh configuration..."

ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/zsh/.zsh_custom" "$HOME/.zsh_custom"
ln -sf "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

# Set Zsh as default shell (Linux)
if [ "$OS" = "Linux" ]; then
if [ "$SHELL" != "$(which zsh)" ]; then
echo "Setting Zsh as default shell..."
chsh -s "$(which zsh)"
fi
fi

# Done
echo ""
echo "Zsh setup complete."
echo "Restart your terminal or run:"
echo ""
echo "source ~/.zshrc"
