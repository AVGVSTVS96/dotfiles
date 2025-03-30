#!/bin/bash

# NVIM is symlinked into the dotfiles repo from it's own repo, stow
# will not symlink it, so this script symlinks it manually

set -e

SOURCE="nvim/.config/nvim"
TARGET="$HOME/.config/nvim"

# Check if the target already exists
if [ -e "$TARGET" ]; then
  echo "Target $TARGET already exists. Please remove it before running this script."
  exit 1
fi

# Create the symlink
ln -s "$(pwd)/$SOURCE" "$TARGET"
echo "Symlink created: $TARGET -> $(pwd)/$SOURCE"
