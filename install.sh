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
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
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

# Setup yazi.nvim plugin configuration
log_step "Setting up yazi.nvim configuration"
mkdir -p "$ACTUAL_HOME/.config/nvim/lua/plugins"

cat > "$ACTUAL_HOME/.config/nvim/lua/plugins/yazi.lua" << 'EOF'
return {
  "mikavilpas/yazi.nvim",
  cmd = { "Yazi", "Yazi cwd", "Yazi toggle" },
  opts = {
    open_multiple_tabs = true,
    yazi_floating_window_border = "single",
    -- Enable yazi.nvim to find the yazi binary even if PATH is incomplete
    yazi_binary_path = "/usr/local/bin/yazi",
    keymaps = {
      show_help = false,
      open_file_in_vertical_split = false,
      open_file_in_horizontal_split = false,
      open_file_in_tab = false,
      grep_in_directory = false,
      replace_in_directory = false,
      cycle_open_buffers = false,
      copy_relative_path_to_selected_files = false,
      send_to_quickfix_list = false,
    },
  },
  keys = {
    { "-", "<cmd>Yazi cwd<cr>", desc = "Open yazi in current directory" },
    { "<c-up>", "<cmd>Yazi toggle<cr>", desc = "Toggle yazi" },
  },
}
EOF

log_info "Created yazi.nvim plugin configuration"

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

# Install file command (required for yazi file type detection)
log_step "Installing file command"
if command -v file &> /dev/null; then
    log_warn "file command is already installed, skipping"
else
    sudo apt-get install -y file
    log_info "file command installed successfully"
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
        sudo mv yazi-x86_64-unknown-linux-gnu/ya /usr/local/bin/
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

# Install fd-find and ripgrep
log_step "Installing fd-find and ripgrep"
if command -v fd &> /dev/null && command -v rg &> /dev/null; then
    log_warn "fd-find and ripgrep are already installed, skipping"
else
    sudo apt-get install -y fd-find ripgrep
    log_info "fd-find and ripgrep installed successfully"
fi

# Install eza (modern ls replacement)
log_step "Installing eza"
if command -v eza &> /dev/null; then
    log_warn "eza is already installed, skipping"
else
    sudo apt-get install -y eza
    log_info "eza installed successfully"
fi

# Install vivid (color generator for terminal)
log_step "Installing vivid"
if command -v vivid &> /dev/null; then
    log_warn "vivid is already installed, skipping"
else
    sudo apt-get install -y vivid
    log_info "vivid installed successfully"
fi

# Ensure yazi is in PATH for desktop environments
log_step "Setting up PATH for desktop environments"
if command -v yazi &> /dev/null; then
    YAZI_PATH=$(which yazi)
    YAZI_DIR=$(dirname "$YAZI_PATH")
    
    # Create desktop entry with proper PATH
    DESKTOP_DIR="$ACTUAL_HOME/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    
    cat > "$DESKTOP_DIR/nvim-yazi.desktop" << EOF
[Desktop Entry]
Name=Neovim (with Yazi support)
GenericName=Text Editor
Comment=Edit text files with Yazi file manager integration
TryExec=nvim
Exec=sh -c "PATH=$YAZI_DIR:\$PATH nvim %F"
Terminal=true
Type=Application
Keywords=Text;editor;
Icon=nvim
Categories=Utility;TextEditor;
StartupNotify=false
MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
EOF
    
    log_info "Created desktop entry with proper PATH at $DESKTOP_DIR/nvim-yazi.desktop"
    
    # Update user's shell profile to ensure PATH includes yazi
    if ! grep -q "$YAZI_DIR" "$ACTUAL_HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$ACTUAL_HOME/.zshrc"
        echo "# Add yazi to PATH" >> "$ACTUAL_HOME/.zshrc"
        echo "export PATH=\"$YAZI_DIR:\$PATH\"" >> "$ACTUAL_HOME/.zshrc"
        log_info "Added yazi PATH to .zshrc"
    fi
fi

# Install Open Code
log_step "Installing OpenCode"
if command -v opencode &> /dev/null; then
    log_warn "opencode is already installed, skipping"
else
    curl -fsSL https://opencode.ai/install | bash
    sudo apt-get install -y procps lsof
    
    # Create symlink to make opencode globally available
    if [ -f "$ACTUAL_HOME/.opencode/bin/opencode" ]; then
        sudo ln -sf "$ACTUAL_HOME/.opencode/bin/opencode" /usr/local/bin/opencode
        log_info "Created global symlink for opencode"
    fi
    
    log_info "OpenCode installed successfully"
fi

log_step "Setting up OpenCode configuration"
mkdir -p "$ACTUAL_HOME/.config/opencode/themes"
if [ -f "$SCRIPT_DIR/.config/opencode/opencode.json" ]; then
    cp "$SCRIPT_DIR/.config/opencode/opencode.json" "$ACTUAL_HOME/.config/opencode/opencode.json"
    log_info "Copied opencode.json"
else
    log_warn "opencode.json not found, skipping"
fi
if [ -f "$SCRIPT_DIR/.config/opencode/themes/transparent-gold-blue.json" ]; then
    cp "$SCRIPT_DIR/.config/opencode/themes/transparent-gold-blue.json" "$ACTUAL_HOME/.config/opencode/themes/transparent-gold-blue.json"
    log_info "Copied transparent-gold-blue theme"
else
    log_warn "transparent-gold-blue theme not found, skipping"
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
log_info ""
log_info "🔧 Yazi.nvim setup notes:"
log_info "- Yazi is installed at /usr/local/bin/ (included in PATH)"
log_info "- Desktop entry created with proper PATH configuration"
log_info "- Plugin configured to use explicit yazi binary path"
log_info "- Use '-' key in nvim to open yazi, or 'Ctrl+Up' to toggle"
