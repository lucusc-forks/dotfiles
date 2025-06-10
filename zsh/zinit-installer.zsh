#!/usr/bin/env zsh
# Zinit installer script
# This script will install Zinit if it doesn't exist

# Define the installation directory
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Check if Zinit is already installed
if [ ! -d "$ZINIT_HOME" ]; then
  echo "Installing Zinit..."
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  echo "Zinit installed successfully!"
else
  echo "Zinit is already installed."
fi
