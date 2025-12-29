#!/bin/bash
set -e

# Fix terminal type
export TERM=xterm-256color
echo 'export TERM=xterm-256color' >> ~/.bashrc

# Install nvim from AppImage
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod u+x nvim-linux-x86_64.appimage

# Extract AppImage
./nvim-linux-x86_64.appimage --appimage-extract

# Exposing nvim globally.
sudo mv squashfs-root /
sudo ln -s /squashfs-root/AppRun /usr/bin/nvim

# User config (sin sudo)
mkdir -p ~/.config/nvim
cp ./nvim.lua ~/.config/nvim/init.lua

# Set up oh-my-posh
curl -s https://ohmyposh.dev/install.sh | bash -s
echo 'eval "$(oh-my-posh init bash --config $(find / -name "avit.omp.json" 2>/dev/null | head -1))"' >> ~/.bashrc

# Update
sudo apt-get update

# Install Open Code
curl -fsSL https://opencode.ai/install | bash
sudo apt-get install -y procps
sudo apt-get install -y lsof
mkdir -p ~/.config/opencode
cp ./opencode.json ~/.config/opencode/opencode.json
