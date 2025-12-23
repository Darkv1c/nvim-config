#!/bin/bash

# Fix terminal type
export TERM=xterm-256color
echo 'export TERM=xterm-256color' >> ~/.bashrc

# Instalar Neovim extrayendo el AppImage (no requiere FUSE)
echo "Descargando Neovim..."
curl -L -o /tmp/nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x /tmp/nvim.appimage

# Extraer el AppImage (no requiere FUSE)
cd /tmp
./nvim.appimage --appimage-extract > /dev/null 2>&1

# Mover el binario extraído
sudo mv squashfs-root /opt/nvim
sudo ln -sf /opt/nvim/AppRun /usr/local/bin/nvim

# Limpiar
rm /tmp/nvim.appimage

# Crear directorio .config
mkdir -p ~/.config

# Hacer symlink a la config de nvim
ln -sf ~/dotfiles ~/.config/nvim

echo "✅ Neovim instalado correctamente"
nvim --version
