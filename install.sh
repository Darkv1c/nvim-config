#!/bin/bash

# Fix terminal type
export TERM=xterm-256color
echo 'export TERM=xterm-256color' >> ~/.bashrc

# Install nvim
wget https://github.com/neovim/neovim/releases/download/v0.11.1/nvim-linux-x86_64.appimage
chmod +x nvim-linux-x86_64.appimage
./nvim-linux-x86_64.appimage --appimage-extract 
mv ./squashfs-root/usr/bin/nvim /usr/bin/nvim

# Set up oh-my-posh
curl -s https://ohmyposh.dev/install.sh | bash -s
oh-my-posh font install Hack
sudo cp ./Hack*.ttf /usr/share/fonts/
echo "eval \"$(oh-my-posh init bash --config /root/.cache/oh-my-posh/themes/jblab_2021.omp.json)\"" >> ~/.bashrc
