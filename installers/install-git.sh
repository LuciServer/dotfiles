#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$DOTFILES_DIR/.env"

echo "Setting up Git..."

# ── Load .env ─────────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env not found. Copy .env.example → .env and fill in your values." >&2
  exit 1
fi

set +u
# shellcheck disable=SC1090
source "$ENV_FILE"
set -u

if [ -z "${GIT_EMAIL:-}" ] || [ -z "${GIT_NAME:-}" ]; then
  echo "ERROR: GIT_NAME and GIT_EMAIL must be set in .env." >&2
  exit 1
fi

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

if ! command -v git >/dev/null; then
  if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y git
  elif load_homebrew || [ "$(uname -s)" = "Darwin" ]; then
    ensure_homebrew
    brew install git
  else
    echo "ERROR: Cannot install git — no supported package manager found (apt/brew)." >&2
    exit 1
  fi
fi

ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# ── Write per-device identity to ~/.gitconfig.local ──────────
#
# ~/.gitconfig.local is included by dotfiles/git/.gitconfig.
# Writing here avoids modifying the symlinked tracked file.
LOCAL_CONFIG="$HOME/.gitconfig.local"

git config --file "$LOCAL_CONFIG" user.name  "$GIT_NAME"
git config --file "$LOCAL_CONFIG" user.email "$GIT_EMAIL"

echo "Git identity set in ~/.gitconfig.local: $GIT_NAME <$GIT_EMAIL>"

# ── SSH rewrite rules → ~/.gitconfig.local ───────────────────
# Only apply if the user has an SSH key configured, to avoid chicken-and-egg
# problems during initial setup (cloning Oh My Zsh, etc.)
echo "Checking for SSH keys to decide on URL rewrite rules..."

git config --file "$LOCAL_CONFIG" --unset-all url."git@github.com:LuciKritZ/".insteadOf 2>/dev/null || true
git config --file "$LOCAL_CONFIG" --unset-all url."git@gitlab.com:krishals.001/".insteadOf 2>/dev/null || true

# Check for any common GitHub/GitLab SSH keys
if [ -f "$HOME/.ssh/github_key" ] || [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
  echo "  Applying GitHub/GitLab SSH rewrite rules..."
  git config --file "$LOCAL_CONFIG" url."git@github.com:LuciKritZ/".insteadOf "https://github.com/LuciKritZ/"
  git config --file "$LOCAL_CONFIG" url."git@gitlab.com:krishals.001/".insteadOf "https://gitlab.com/krishals.001/"
else
  echo "  No SSH keys found. Skipping rewrite rules (clones will use HTTPS)."
fi

echo "Git configured."
