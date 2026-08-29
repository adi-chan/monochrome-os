#!/usr/bin/env bash

# ==============================================================================
# Monochrome OS - Automated Setup & Installation Script
# https://github.com/adi-chan/monochrome-os
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}      Installing Monochrome OS Setup & Config       ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Package Installation
echo -e "\n${YELLOW}[1/5] Checking and installing dependencies...${NC}"

if command -v pacman &>/dev/null; then
    echo "Installing base official packages..."
    sudo pacman -Syu --needed --noconfirm \
        hyprland \
        mpd mpc \
        cava \
        dunst \
        pipewire pipewire-pulse wireplumber \
        python3 \
        ttf-jetbrains-mono-nerd
else
    echo -e "${RED}Warning: Pacman not found. Please manually install dependencies on your distro.${NC}"
fi

# AUR packages
if command -v yay &>/dev/null; then
    echo "Installing Quickshell via yay..."
    yay -S --needed --noconfirm quickshell-git
elif command -v paru &>/dev/null; then
    echo "Installing Quickshell via paru..."
    paru -S --needed --noconfirm quickshell-git
else
    echo -e "${RED}Warning: Neither yay nor paru found. Please install 'quickshell-git' manually from AUR.${NC}"
fi

# 2. Setup Music Presence
echo -e "\n${YELLOW}[2/5] Setting up Music Presence (Discord Rich Presence)...${NC}"
mkdir -p "$HOME/tools"
MUSIC_PRESENCE_PATH="$HOME/tools/musicpresence-2.3.6-linux-x86_64.AppImage"

if [ ! -f "$MUSIC_PRESENCE_PATH" ]; then
    echo "Downloading Music Presence AppImage..."
    curl -L -o "$MUSIC_PRESENCE_PATH" \
        https://github.com/ungit/music-presence/releases/download/v2.3.6/musicpresence-2.3.6-linux-x86_64.AppImage
fi
chmod +x "$MUSIC_PRESENCE_PATH"
echo -e "${GREEN}✓ Music Presence ready at ~/tools/musicpresence-2.3.6-linux-x86_64.AppImage${NC}"

# 3. Enable MPD Service
echo -e "\n${YELLOW}[3/5] Enabling MPD Music Service...${NC}"
systemctl --user enable --now mpd || echo "Note: Start MPD manually if running outside systemd."
echo -e "${GREEN}✓ MPD service enabled.${NC}"

# 4. Set GTK Font
echo -e "\n${YELLOW}[4/5] Setting System Font (JetBrains Mono)...${NC}"
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface font-name 'JetBrains Mono 11' || true
    echo -e "${GREEN}✓ GTK font updated to JetBrains Mono 11.${NC}"
fi

# 5. Hyprland Keybind Guidance
echo -e "\n${YELLOW}[5/5] Checking Hyprland Configuration...${NC}"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

if [ -f "$HYPR_CONF" ]; then
    if ! grep -q "quickshell" "$HYPR_CONF"; then
        echo -e "\n${YELLOW}Adding Quickshell startup & keybinds to $HYPR_CONF...${NC}"
        cat << 'EOF' >> "$HYPR_CONF"

# --- Monochrome OS / Quickshell Config ---
exec-once = quickshell

# Shortcut Wheel (Hold SUPER + Tab)
bind = SUPER, Tab, exec, sh -c 'touch /tmp/qs_wheel_holding; sleep 0.15; if [ -f /tmp/qs_wheel_holding ]; then touch /tmp/qs_wheel_open; fi'
bindrt = SUPER, Tab, exec, rm -f /tmp/qs_wheel_holding /tmp/qs_wheel_open
EOF
        echo -e "${GREEN}✓ Added Quickshell keybinds to hyprland.conf.${NC}"
    else
        echo -e "${GREEN}✓ Quickshell config already present in hyprland.conf.${NC}"
    fi
fi

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}  ✓ Installation Complete! Launching Quickshell... ${NC}"
echo -e "${GREEN}====================================================${NC}"

if command -v quickshell &>/dev/null; then
    quickshell &
fi
