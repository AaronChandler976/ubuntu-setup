#!/usr/bin/env bash
# One-line bootstrapper for ubuntu-setup. On a fresh Ubuntu, open Terminal and run:
#
#   wget -qO- https://raw.githubusercontent.com/AaronChandler976/ubuntu-setup/main/install.sh | bash
#
# With options (anything setup.sh accepts):
#
#   wget -qO- https://raw.githubusercontent.com/AaronChandler976/ubuntu-setup/main/install.sh | bash -s -- --robotics --ml-env
set -euo pipefail

OWNER=AaronChandler976
REPO=ubuntu-setup
BRANCH=${UBUNTU_SETUP_BRANCH:-main}
DEST="$HOME/.local/share/ubuntu-setup"
URL="https://github.com/$OWNER/$REPO/archive/refs/heads/$BRANCH.tar.gz"

echo "> Downloading $URL"
tmp=$(mktemp -d)
if command -v curl >/dev/null; then curl -fsSL "$URL" | tar -xz -C "$tmp"
else wget -qO- "$URL" | tar -xz -C "$tmp"; fi

rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
mv "$tmp/$REPO-$BRANCH" "$DEST"
rm -rf "$tmp"
echo "> Saved to $DEST"

# When piped into bash, stdin is this script - give setup.sh the real keyboard.
if [[ -r /dev/tty ]]; then
    exec bash "$DEST/setup.sh" "$@" </dev/tty
else
    exec bash "$DEST/setup.sh" "$@"
fi
