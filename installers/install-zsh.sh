#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_HOME="${HOME:-$(getent passwd "$USER" | cut -d: -f6)}"

if [ -z "$USER_HOME" ]; then
  echo "ERROR: Could not determine home directory. Aborting." >&2
  exit 1
fi

echo "────────────────────────────────────────"
echo "Installing Zsh environment"
echo "User: $USER"
echo "Home: $USER_HOME"
echo "Dotfiles: $DOTFILES_DIR"
echo "────────────────────────────────────────"

if command -v apt >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y zsh git curl
elif command -v brew >/dev/null 2>&1; then
  brew install zsh git curl
fi

if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."

  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}"

mkdir -p "$ZSH_CUSTOM/plugins"
mkdir -p "$ZSH_CUSTOM/plugins"
mkdir -p "$ZSH_CUSTOM/themes"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "Installing zsh-autosuggestions..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "Installing zsh-syntax-highlighting..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  echo "Installing powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

echo "Installing Zsh configuration..."

# ── Safe copy helper ──────────────────────────────────────────
# Backs up any existing regular file before overwriting.
# Symlinks are always replaced (they point to a previous install).
_safe_copy() {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -f "$dest" ]; then
    BACKUP="${dest}.bak.$(date +%Y%m%d%H%M%S)"
    echo "  Backing up existing $(basename "$dest") → $BACKUP"
    mv "$dest" "$BACKUP"
  fi
  cp "$src" "$dest"
}

_safe_copy "$DOTFILES_DIR/zsh/.zshrc" "$USER_HOME/.zshrc"

if [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]; then
  _safe_copy "$DOTFILES_DIR/zsh/.p10k.zsh" "$USER_HOME/.p10k.zsh"
fi

if [ -f "$DOTFILES_DIR/zsh/.zsh_custom" ]; then
  _safe_copy "$DOTFILES_DIR/zsh/.zsh_custom" "$USER_HOME/.zsh_custom"
fi

# zsh-utils: symlink the whole directory so changes propagate without re-running
if [ -d "$DOTFILES_DIR/zsh-utils" ]; then
  rm -rf "$USER_HOME/.zsh-utils"
  ln -sf "$DOTFILES_DIR/zsh-utils" "$USER_HOME/.zsh-utils"
fi

# Ensure ~/.zshrc.local exists as a machine-specific escape hatch.
# It is sourced by .zshrc but never overwritten by the installer.
if [ ! -f "$USER_HOME/.zshrc.local" ]; then
  cat > "$USER_HOME/.zshrc.local" <<'EOF'
# ~/.zshrc.local — machine-specific Zsh config.
# This file is never overwritten by the dotfiles installer.
# Add anything that should only apply to this device here.
EOF
  echo "Created ~/.zshrc.local (machine-specific, never overwritten)"
fi

ZSH_BIN="$(command -v zsh)"

if ! grep -qx "$ZSH_BIN" /etc/shells; then
  echo "Adding $ZSH_BIN to /etc/shells"
  echo "$ZSH_BIN" | sudo tee -a /etc/shells > /dev/null
fi

if [ "$SHELL" != "$ZSH_BIN" ]; then
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
