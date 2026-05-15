#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$DOTFILES_DIR/.env"

echo "────────────────────────────────────────"
echo "Setting up GPG signing"
echo "Host: $(hostname)"
echo "────────────────────────────────────────"

# Ensure GPG knows which TTY to use for passphrase prompts
export GPG_TTY=$(tty 2>/dev/null || echo "")

# ── 1. Load .env ──────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env not found." >&2
  echo "  Copy .env.example → .env and fill in your values:" >&2
  echo "  cp \"$DOTFILES_DIR/.env.example\" \"$DOTFILES_DIR/.env\"" >&2
  exit 1
fi

# shellcheck source=../.env
set +u
# shellcheck disable=SC1090
source "$ENV_FILE"
set -u

# ── 2. Validate required variables ───────────────────────────
if [ -z "${GIT_EMAIL:-}" ]; then
  echo "ERROR: GIT_EMAIL is not set in .env." >&2
  exit 1
fi

if [ -z "${GIT_NAME:-}" ]; then
  echo "ERROR: GIT_NAME is not set in .env." >&2
  exit 1
fi

# ── 3. Check for opt-out ──────────────────────────────────────
if [ "${SKIP_GPG:-}" = "true" ]; then
  echo "SKIP_GPG is set to true. Skipping GPG setup."
  exit 0
fi

GPG_KEY_TYPE="ed25519"
GPG_EXPIRE="2y"

# ── 3. Install gpg if missing ─────────────────────────────────
if ! command -v gpg >/dev/null 2>&1; then
  echo "Installing gnupg..."
  if command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y gnupg
  elif command -v brew >/dev/null 2>&1; then
    brew install gnupg
  else
    echo "ERROR: Cannot install gpg — no supported package manager (apt/brew)." >&2
    exit 1
  fi
fi

# ── 4. Determine signing key ──────────────────────────────────

_get_local_key() {
  gpg --list-secret-keys --keyid-format LONG "$GIT_EMAIL" 2>/dev/null \
    | grep -E "^sec" \
    | awk '{print $2}' \
    | cut -d'/' -f2 \
    | head -n1 || true
}

_show_public_key() {
  local key_id="$1"
  local public_key
  public_key="$(gpg --armor --export "$key_id")"

  echo ""
  echo "════════════════════════════════════════"
  echo "  ACTION REQUIRED — Add this key to GitHub / GitLab"
  echo "════════════════════════════════════════"
  echo ""
  echo "  Host:    $(hostname)"
  echo "  Key ID:  $key_id"
  echo ""
  echo "  → GitHub:  https://github.com/settings/gpg/new"
  echo "  → GitLab:  https://gitlab.com/-/user_settings/gpg_keys"
  echo ""
  echo "Copy the entire block below (including the header and footer):"
  echo ""
  echo "$public_key"
  echo ""
  echo "════════════════════════════════════════"
}

SIGNING_KEY=""

# ── Case A: GPG_SOURCE_HOST is configured — fetch from server ─
if [ -n "${GPG_SOURCE_HOST:-}" ]; then
  echo "GPG_SOURCE_HOST is set. Fetching key from $GPG_SOURCE_HOST..."

  # We bundle the Key ID and the exported key together on the remote host
  # to reduce the number of SSH calls (and password prompts).
  REMOTE_TMP=".gpg_bundle_fetch.tmp"
  REMOTE_CMD="export GPG_TTY=\$(tty); 
    GPG_ID=\$(gpg --list-secret-keys --keyid-format LONG '$GIT_EMAIL' 2>/dev/null | grep '^sec' | awk '{print \$2}' | cut -d'/' -f2 | head -n1);
    echo \"\$GPG_ID\" > $REMOTE_TMP;
    gpg --armor --export-secret-keys '$GIT_EMAIL' >> $REMOTE_TMP"

  if ssh -t "$GPG_SOURCE_HOST" "$REMOTE_CMD"; then
    BUNDLE="$(ssh "$GPG_SOURCE_HOST" "cat $REMOTE_TMP && rm $REMOTE_TMP" | tr -d '\r' || true)"
    SIGNING_KEY="$(echo "$BUNDLE" | head -n 1 | xargs)" # xargs trims whitespace
    FETCHED_KEY="$(echo "$BUNDLE" | tail -n +2)"
  fi

  if [ -z "$SIGNING_KEY" ] || [ -z "$FETCHED_KEY" ]; then
    echo "" >&2
    echo "ERROR: Failed to fetch GPG key or ID from $GPG_SOURCE_HOST." >&2
    echo "" >&2
    echo "Possible causes:" >&2
    echo "  - SSH connection failed (check GPG_SOURCE_HOST in .env)" >&2
    echo "  - No key for $GIT_EMAIL exists on the source host" >&2
    echo "  - gpg passphrase was incorrect" >&2
    exit 1
  fi

  # Clean up any existing keys for this email to ensure a clean import
  echo "Cleaning up existing local GPG keys for $GIT_EMAIL..."
  gpg --list-secret-keys --with-colons "$GIT_EMAIL" 2>/dev/null | grep '^sec' | cut -d: -f5 | xargs gpg --batch --yes --delete-secret-and-public-keys 2>/dev/null || true

  # Strip any carriage returns or hidden ANSI/TTY artifacts from the key data
  # Use a local temporary file for import to avoid stdin/TTY conflicts
  LOCAL_TMP_KEY=".gpg_import_$(date +%s).tmp"
  echo "$FETCHED_KEY" | tr -d '\r' | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' > "$LOCAL_TMP_KEY"

  echo "Importing key into local keyring..."
  if gpg --import "$LOCAL_TMP_KEY"; then
    echo "✅ Key imported from $GPG_SOURCE_HOST."
    rm -f "$LOCAL_TMP_KEY"
  else
    echo "ERROR: GPG import failed. The fetched key data might be malformed." >&2
    rm -f "$LOCAL_TMP_KEY"
    exit 1
  fi


# ── Case B: No source — check local, then prompt user ─────────
else
  SIGNING_KEY="$(_get_local_key)"

  if [ -n "$SIGNING_KEY" ]; then
    echo "✅ Existing GPG key found on this device: $SIGNING_KEY"
    echo "   Reusing it — no new key will be generated."
  else
    echo ""
    echo "No GPG key found for $GIT_EMAIL on this machine."
    echo "GPG_SOURCE_HOST is not configured in .env."
    echo ""
    printf "Would you like to generate a new GPG signing key for this device? [y/N] "
    read -r REPLY </dev/tty

    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
      echo ""
      echo "Skipping GPG key generation."
      echo "Git commit signing will NOT be configured on this machine."
      echo ""
      echo "To set this up later:"
      echo "  1. Set GPG_SOURCE_HOST in .env (to import from another machine)"
      echo "  2. Or re-run: bash installers/install-gpg.sh"
      exit 0
    fi

    echo ""
    echo "Generating a new GPG key for $GIT_NAME <$GIT_EMAIL> on $(hostname)..."

    gpg --batch --gen-key <<EOF
%no-protection
Key-Type: $GPG_KEY_TYPE
Key-Usage: sign
Name-Real: $GIT_NAME ($(hostname))
Name-Email: $GIT_EMAIL
Expire-Date: $GPG_EXPIRE
%commit
EOF

    SIGNING_KEY="$(_get_local_key)"

    if [ -z "$SIGNING_KEY" ]; then
      echo "ERROR: Could not extract key ID after generation." >&2
      exit 1
    fi

    echo "✅ New key generated: $SIGNING_KEY"
    _show_public_key "$SIGNING_KEY"

    echo ""
    printf "Press ENTER once you have added the key to GitHub/GitLab to continue..."
    read -r </dev/tty
  fi
fi

# ── Configure git signing in ~/.gitconfig.local ───────────────
LOCAL_CONFIG="$HOME/.gitconfig.local"

git config --file "$LOCAL_CONFIG" user.signingkey "$SIGNING_KEY"
git config --file "$LOCAL_CONFIG" commit.gpgsign  true
git config --file "$LOCAL_CONFIG" gpg.program     gpg

echo ""
echo "Git configured to sign commits with key: $SIGNING_KEY"

# ── 6. Start gpg-agent ────────────────────────────────────────
GPG_TTY_VAL="$(tty 2>/dev/null || echo "")"
if [ -n "$GPG_TTY_VAL" ]; then
  export GPG_TTY="$GPG_TTY_VAL"
  gpgconf --launch gpg-agent
fi

echo ""
echo "GPG setup complete."
echo ""
