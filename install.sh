#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${GREEN}==>${NC} $1"
}

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Detect the actual user (not root if running via sudo)
if [ -n "$SUDO_USER" ]; then
    ACTUAL_USER="$SUDO_USER"
    ACTUAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
elif [ "$USER" = "root" ] && [ -n "$DEVPOD_USER" ]; then
    # DevPod might set this
    ACTUAL_USER="$DEVPOD_USER"
    ACTUAL_HOME=$(getent passwd "$DEVPOD_USER" | cut -d: -f6)
elif [ "$USER" = "root" ]; then
    # Try to find a non-root user in the container
    ACTUAL_USER=$(getent passwd 1000 | cut -d: -f1)
    if [ -z "$ACTUAL_USER" ]; then
        ACTUAL_USER="$USER"
        ACTUAL_HOME="$HOME"
    else
        ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
    fi
else
    ACTUAL_USER="$USER"
    ACTUAL_HOME="$HOME"
fi

log_info "Starting dotfiles installation from: $SCRIPT_DIR"
log_info "Installing for user: $ACTUAL_USER (home: $ACTUAL_HOME)"

# Update
log_step "Updating package lists"
sudo apt-get update

# Install zsh
log_step "Installing zsh"
if command -v zsh &> /dev/null; then
    log_warn "zsh is already installed, skipping"
else
    sudo apt-get install -y zsh
    log_info "zsh installed successfully"
fi

# Install starship prompt
log_step "Installing starship prompt"
if command -v starship &> /dev/null; then
    log_warn "starship is already installed, skipping"
else
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    log_info "starship installed successfully"
fi

# Set zsh as default shell
log_step "Setting zsh as default shell"
if [ "$SHELL" = "$(which zsh)" ]; then
    log_warn "zsh is already the default shell"
else
    chsh -s $(which zsh) || log_warn "Failed to set zsh as default shell (may require logout)"
fi

# Install nvim from AppImage
log_step "Installing neovim"
if command -v nvim &> /dev/null && [ -d /squashfs-root ]; then
    log_warn "nvim is already installed, skipping"
else
    log_info "Downloading neovim AppImage"
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
    chmod u+x nvim-linux-x86_64.appimage
    
    log_info "Extracting AppImage"
    ./nvim-linux-x86_64.appimage --appimage-extract
    
    log_info "Installing nvim globally"
    # Remove existing installation if it exists
    if [ -d /squashfs-root ]; then
        log_info "Removing old nvim installation"
        sudo rm -rf /squashfs-root
    fi
    sudo mv squashfs-root /
    sudo ln -sf /squashfs-root/AppRun /usr/bin/nvim
    
    log_info "Cleaning up"
    rm -f nvim-linux-x86_64.appimage
    
    log_info "nvim installed successfully"
fi

# Neovim configuration
log_step "Setting up neovim configuration"
mkdir -p "$ACTUAL_HOME/.config/nvim/lua/plugins"

if [ -f "$SCRIPT_DIR/.config/nvim/init.lua" ]; then
    cp "$SCRIPT_DIR/.config/nvim/init.lua" "$ACTUAL_HOME/.config/nvim/init.lua"
    log_info "Copied init.lua"
else
    log_error "init.lua not found in $SCRIPT_DIR/.config/nvim/"
fi

for plugin_file in core.lua study.lua work.lua; do
    if [ -f "$SCRIPT_DIR/.config/nvim/lua/plugins/$plugin_file" ]; then
        cp "$SCRIPT_DIR/.config/nvim/lua/plugins/$plugin_file" "$ACTUAL_HOME/.config/nvim/lua/plugins/$plugin_file"
        log_info "Copied $plugin_file"
    else
        log_warn "$plugin_file not found, skipping"
    fi
done

# Zsh and Starship configuration
log_step "Setting up shell configuration"
mkdir -p "$ACTUAL_HOME/.config"

if [ -f "$SCRIPT_DIR/.zshrc" ]; then
    cp "$SCRIPT_DIR/.zshrc" "$ACTUAL_HOME/.zshrc"
    log_info "Copied .zshrc"
else
    log_error ".zshrc not found"
fi

if [ -f "$SCRIPT_DIR/.config/starship.toml" ]; then
    cp "$SCRIPT_DIR/.config/starship.toml" "$ACTUAL_HOME/.config/starship.toml"
    log_info "Copied starship.toml"
else
    log_error "starship.toml not found"
fi

# Install yazi (file manager)
log_step "Installing yazi file manager"
if command -v yazi &> /dev/null; then
    log_warn "yazi is already installed, skipping"
else
    log_info "Checking GLIBC version for yazi compatibility"
    GLIBC_VERSION=$(ldd --version | head -1 | grep -oP '\d+\.\d+$')
    
    # yazi requires GLIBC 2.38+ (available in Ubuntu 24.04+, Debian 13+)
    if awk -v ver="$GLIBC_VERSION" 'BEGIN { exit (ver >= 2.38) ? 0 : 1 }'; then
        log_info "GLIBC $GLIBC_VERSION detected - installing yazi"
        # Install unzip if not available
        if ! command -v unzip &> /dev/null; then
            sudo apt-get install -y unzip
        fi
        curl -LO https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
        unzip -q yazi-x86_64-unknown-linux-gnu.zip
        sudo mv yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/
        rm -rf yazi-x86_64-unknown-linux-gnu yazi-x86_64-unknown-linux-gnu.zip
        log_info "yazi installed successfully"
    else
        log_warn "GLIBC $GLIBC_VERSION is too old for yazi (requires 2.38+)"
        log_info "Installing lf as alternative file manager"
        curl -LO "https://github.com/gokcehan/lf/releases/latest/download/lf-linux-amd64.tar.gz"
        tar -xzf lf-linux-amd64.tar.gz
        sudo mv lf /usr/local/bin/
        rm -f lf-linux-amd64.tar.gz
        log_info "lf installed successfully as yazi alternative"
    fi
fi

# Install Open Code
log_step "Installing OpenCode"
if command -v opencode &> /dev/null; then
    log_warn "opencode is already installed, skipping"
else
    curl -fsSL https://opencode.ai/install | bash
    sudo apt-get install -y procps lsof
    log_info "OpenCode installed successfully"
fi

log_step "Setting up OpenCode configuration"
mkdir -p "$ACTUAL_HOME/.config/opencode"
if [ -f "$SCRIPT_DIR/opencode.json" ]; then
    cp "$SCRIPT_DIR/opencode.json" "$ACTUAL_HOME/.config/opencode/opencode.json"
    log_info "Copied opencode.json"
else
    log_warn "opencode.json not found, skipping"
fi

# Fix permissions if running as root
if [ "$USER" = "root" ] && [ "$ACTUAL_USER" != "root" ]; then
    log_step "Fixing file permissions for $ACTUAL_USER"
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.config" "$ACTUAL_HOME/.zshrc" 2>/dev/null || true
    log_info "Permissions updated"
fi

# Set zsh as default shell for the actual user
if [ "$ACTUAL_USER" != "root" ]; then
    log_step "Setting zsh as default shell for $ACTUAL_USER"
    chsh -s $(which zsh) "$ACTUAL_USER" 2>/dev/null || log_warn "Could not set zsh as default (may require manual change)"
fi

log_info ""
log_info "✓ Installation complete!"
log_info "Please log out and log back in for zsh to take effect."
log_info "Or run: exec zsh"
