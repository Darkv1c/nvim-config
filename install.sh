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
mkdir -p ~/.poshthemes
wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O ~/.poshthemes/themes.zip
unzip ~/.poshthemes/themes.zip -d ~/.poshthemes
chmod u+rw ~/.poshthemes/*.json
rm ~/.poshthemes/themes.zip
eval "$(oh-my-posh init bash --config ~/.poshthemes/jblab_2021.omp.json)"

