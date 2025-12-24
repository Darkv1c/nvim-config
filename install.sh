#!/bin/bash
set -e

# Fix terminal type
export TERM=xterm-256color
echo 'export TERM=xterm-256color' >> ~/.bashrc

# Install nvim from AppImage
wget https://github.com/neovim/neovim/releases/download/v0.11.1/nvim-linux-x86_64.appimage
chmod +x nvim-linux-x86_64.appimage
./nvim-linux-x86_64.appimage --appimage-extract

sudo mv squashfs-root/usr/bin/nvim /usr/local/bin/nvim
sudo mkdir -p /usr/local/share
sudo cp -r squashfs-root/usr/share/nvim /usr/local/share/

rm -rf squashfs-root nvim-linux-x86_64.appimage

# User config (sin sudo)
mkdir -p ~/.config/nvim
cp ./nvim.lua ~/.config/nvim/init.lua

# Set up oh-my-posh
curl -s https://ohmyposh.dev/install.sh | bash -s
echo 'eval "$(oh-my-posh init bash --config /root/.cache/oh-my-posh/themes/jblab_2021.omp.json)"' >> ~/.bashrc
