#!/bin/bash

# Descargar la última versión de Neovim (AppImage)
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage

# Hacerlo ejecutable
chmod u+x nvim.appimage

# Moverlo a /usr/local/bin y renombrarlo a nvim
sudo mv nvim.appimage /usr/local/bin/nvim

echo "Neovim instalado correctamente"
nvim --version
