#!/bin/bash

# Exit on any error
set -e

# Check if Homebrew is installed; install if not
if ! command -v brew &>/dev/null; then
	echo "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	# Set PATH for this script session (macOS ARM path; adjust if needed)
	eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Homebrew packages
echo "Installing packages from Brewfile..."
brew bundle --file=~/dotfiles/homebrew/Brewfile

# stow
echo "Setting up dotfiles with stow..."
cd ~/dotfiles
stow .
