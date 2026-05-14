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
