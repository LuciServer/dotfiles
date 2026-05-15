#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting up SSH..."

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# ── Use config.d/ drop-in pattern ────────────────────────────
#
# We do NOT replace ~/.ssh/config — that would wipe any
# system-specific entries already on this machine.
#
# Instead we:
#   1. Symlink our config into ~/.ssh/config.d/dotfiles.conf
#   2. Ensure ~/.ssh/config has an Include line at the top
#      that loads all config.d/*.conf files
#
# This is purely additive — existing entries are preserved.

mkdir -p "$HOME/.ssh/config.d"

ln -sf "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config.d/dotfiles.conf"
chmod 600 "$DOTFILES_DIR/ssh/config"

touch "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

INCLUDE_LINE="Include ~/.ssh/config.d/*.conf"

if ! grep -qF "$INCLUDE_LINE" "$HOME/.ssh/config"; then
  # Prepend to the top (Include must come before any Host blocks)
  TMPFILE="$(mktemp)"
  {
    echo "$INCLUDE_LINE"
    echo ""
    cat "$HOME/.ssh/config"
  } > "$TMPFILE"
  mv "$TMPFILE" "$HOME/.ssh/config"
  echo "Added SSH Include directive to ~/.ssh/config"
else
  echo "SSH Include directive already present — skipping."
fi

echo "SSH configured."

# ── GitHub SSH Key Generation ─────────────────────────────────
GITHUB_KEY="$HOME/.ssh/github_key"

if [ ! -f "$GITHUB_KEY" ]; then
  echo ""
  echo "No GitHub SSH key found at $GITHUB_KEY"
  echo "Generating a new Ed25519 key for GitHub..."
  
  # Get email from .env if available, otherwise use default
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  ENV_FILE="$DOTFILES_DIR/.env"
  SSH_EMAIL="lucikritz@users.noreply.github.com"
  if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1091
    source "$ENV_FILE"
    SSH_EMAIL="${GIT_EMAIL:-$SSH_EMAIL}"
  fi

  ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$GITHUB_KEY" -N ""
  chmod 600 "$GITHUB_KEY"
  chmod 644 "${GITHUB_KEY}.pub"
  
  echo ""
  echo "✅ New SSH key generated: $GITHUB_KEY"
  echo "─────────────────────────────────────────────────────────────────"
  echo "ACTION REQUIRED: Add this public key to your GitHub account:"
  echo "https://github.com/settings/keys"
  echo "─────────────────────────────────────────────────────────────────"
  cat "${GITHUB_KEY}.pub"
  echo "─────────────────────────────────────────────────────────────────"
  echo ""
else
  echo "Found existing GitHub SSH key at $GITHUB_KEY"
fi
