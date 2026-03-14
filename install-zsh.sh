#!/usr/bin/env bash
set -e

DOTFILES_DIR="$HOME/dotfiles"
ZSH_UTILS_DIR="$HOME/.zsh-utils"

echo "Installing Zsh configuration..."

# Ensure directories exist
mkdir -p "$ZSH_UTILS_DIR"

# Install Oh My Zsh if missing
if [ ! -d "$HOME/.oh-my-zsh" ]; then
echo "Installing Oh My Zsh..."
RUNZSH=no CHSH=no sh -c 
"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install Powerlevel10k theme
P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

if [ ! -d "$P10K_DIR" ]; then
echo "Installing Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# Symlink zsh config files
ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/zsh/.zsh_custom" "$HOME/.zsh_custom"
ln -sf "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

# Install utility scripts
cp -f "$DOTFILES_DIR/zsh-utils/"* "$ZSH_UTILS_DIR/"

# Ensure executables
chmod +x "$ZSH_UTILS_DIR/"*

echo "Zsh utilities installed in ~/.zsh-utils"

echo "Setup complete."
echo "Restart shell or run: source ~/.zshrc"
