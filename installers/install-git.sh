#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS="$(uname -s)"
OUTPUT_DIR="$DOTFILES_DIR/output/gpg"

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

  if [ "$OS" != "Darwin" ]; then
    return 1
  fi

  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew
}

install_packages() {
  if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y "$@"
  elif [ "$OS" = "Darwin" ]; then
    ensure_homebrew
    brew install "$@"
  else
    echo "Error: Unable to install required packages automatically on this operating system."
    exit 1
  fi
}

ensure_line_in_file() {
  local file_path="$1"
  local line="$2"

  touch "$file_path"

  if ! grep -Fqx "$line" "$file_path"; then
    printf '%s\n' "$line" >> "$file_path"
  fi
}

get_secret_key_fingerprint() {
  local lookup="${1:-}"

  if [ -z "$lookup" ]; then
    return 0
  fi

  gpg --list-secret-keys --with-colons "$lookup" 2>/dev/null | awk -F: '/^fpr:/ { print $10; exit }' || true
}

ensure_git() {
  if ! command -v git >/dev/null 2>&1; then
    install_packages git
  fi
}

ensure_gpg_tools() {
  if command -v gpg >/dev/null 2>&1; then
    if [ "$OS" = "Darwin" ] && ! command -v pinentry-mac >/dev/null 2>&1; then
      install_packages pinentry-mac
    fi
    if [ "$OS" != "Darwin" ] && ! command -v pinentry >/dev/null 2>&1 && ! command -v pinentry-curses >/dev/null 2>&1; then
      install_packages pinentry-curses
    fi
    return 0
  fi

  if command -v apt >/dev/null 2>&1; then
    install_packages gnupg pinentry-curses
  elif [ "$OS" = "Darwin" ]; then
    install_packages gnupg pinentry-mac
  else
    echo "Error: Unable to install GPG automatically on this operating system."
    exit 1
  fi
}

configure_gpg_agent() {
  mkdir -p "$HOME/.gnupg"
  chmod 700 "$HOME/.gnupg"

  if [ "$OS" = "Darwin" ]; then
    local pinentry_path
    pinentry_path="$(command -v pinentry-mac || true)"

    if [ -n "$pinentry_path" ]; then
      ensure_line_in_file "$HOME/.gnupg/gpg-agent.conf" "pinentry-program $pinentry_path"
    fi
  fi

  export GPG_TTY="${GPG_TTY:-$(tty 2>/dev/null || true)}"
  gpgconf --kill gpg-agent >/dev/null 2>&1 || true
}

export_signing_key_material() {
  local signing_key="$1"
  local export_dir public_key_file private_key_file instructions_file

  export_dir="$OUTPUT_DIR/$signing_key"
  public_key_file="$export_dir/public.asc"
  private_key_file="$export_dir/private.asc"
  instructions_file="$export_dir/instructions.txt"

  mkdir -p "$export_dir"
  chmod 700 "$OUTPUT_DIR" "$export_dir"

  gpg --armor --export "$signing_key" > "$public_key_file"
  gpg --armor --export-secret-keys "$signing_key" > "$private_key_file"

  chmod 644 "$public_key_file"
  chmod 600 "$private_key_file"

  cat > "$instructions_file" <<EOF
Signing key fingerprint: $signing_key

Files in this folder:
- public.asc: upload this public key to GitHub/GitLab signing keys
- private.asc: import this only on trusted machines you control

GitHub:
1. Open https://github.com/settings/keys
2. Choose "New GPG key"
3. Paste the contents of public.asc

GitLab:
1. Open https://gitlab.com/-/profile/gpg_keys
2. Paste the contents of public.asc

Import on another trusted machine:
gpg --import private.asc

Verify the imported secret key:
gpg --list-secret-keys --keyid-format=long

Verify Git is using this signing key:
git config --global user.signingkey

Verify GPG signing locally:
echo "test" | gpg --clearsign

Verify a signed commit locally:
git commit --allow-empty -S -m "test gpg signing"
git log --show-signature -1

Do not upload private.asc to GitHub, GitLab, or any public location.
EOF

  chmod 600 "$instructions_file"

  echo "Exported GPG key materials to $export_dir"
}

ensure_signing_key() {
  local git_name git_email configured_key signing_key user_id

  git_name="$(git config --global user.name || true)"
  git_email="$(git config --global user.email || true)"

  if [ -z "$git_name" ] || [ -z "$git_email" ]; then
    echo "Error: Git user.name and user.email must be configured before creating a GPG key."
    exit 1
  fi

  configured_key="$(git config --global user.signingkey || true)"
  signing_key="$(get_secret_key_fingerprint "$configured_key")"

  if [ -z "$signing_key" ]; then
    signing_key="$(get_secret_key_fingerprint "$git_email")"
  fi

  if [ -z "$signing_key" ]; then
    if [ ! -t 0 ]; then
      echo "Error: No GPG secret key found for $git_email and interactive key generation is unavailable."
      exit 1
    fi

    user_id="$git_name <$git_email>"
    echo "Generating a new GPG key for $user_id..."
    gpg --quick-generate-key "$user_id" default default 1y
    signing_key="$(get_secret_key_fingerprint "$git_email")"
  fi

  if [ -z "$signing_key" ]; then
    echo "Error: Unable to determine a GPG signing key."
    exit 1
  fi

  git config --global gpg.program "$(command -v gpg)"
  git config --global gpg.format openpgp
  git config --global commit.gpgsign true
  git config --global user.signingkey "$signing_key"

  export_signing_key_material "$signing_key"
}

ensure_git
ensure_gpg_tools
configure_gpg_agent

rm -f "$HOME/.gitconfig"
cp "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

echo "Cleaning malformed Git URL rewrites..."

git config --global --unset-all url.git@github.com:.insteadOf 2>/dev/null || true
git config --global --unset-all url.git@gitlab.com:.insteadOf 2>/dev/null || true

echo "Applying SSH rewrite rules..."

git config --global url."git@github.com:".insteadOf https://github.com/
git config --global url."git@gitlab.com:".insteadOf https://gitlab.com/

ensure_signing_key

echo "Git configured."
