#!/bin/bash

# Merged SovereignKey Script (sk.sh) - Optimized for TailsOS

#------------------------------------------------------
# Config
USER="amnesia"
START_DIR="/home/${USER}/Persistent"
INSTALL_DIR="${START_DIR}/SK"
LOGO_NAME="SKmedium.jpeg"
LOGO_SOURCE_PATH="${START_DIR}/${LOGO_NAME}"
LOGO_DEST_PATH="${INSTALL_DIR}/${LOGO_NAME}"
DESKTOP_FILE_NAME="SovereignKey.desktop"
DESKTOP_FILE_DEST_DIR="/home/${USER}/.local/share/applications"
MAX_APT_RETRIES=3
APT_RETRY_DELAY=5

#------------------------------------------------------
# Colors
Y="\033[1;33m"    # Yellow
G="\033[0;32m"    # Green
LR="\033[1;31m"   # Light Red
NC="\033[0m"      # No Color

#------------------------------------------------------
# Initial Setup
clear
set -e

echo -e "${Y}=== SovereignKey Setup for TailsOS ===${NC}"
echo
echo -e "${Y}This script will:${NC}"
echo "1. Configure system theme (Dark Mode)"
echo "2. Set terminal colors (Namibian flag colors)"
echo "3. Install Visual Studio Codium (AppImage)"
echo "4. Create application shortcut(s)"
echo
echo -e "${LR}Press Enter to continue or Ctrl+C to cancel${NC}"
read -r

#------------------------------------------------------
# Sudo Setup
echo
echo -e "${Y}Enter sudo password:${NC}"
read -r -s -p "Password: " sudoPW
if ! echo "$sudoPW" | sudo -S -v; then
    echo -e "\n${LR}Invalid password. Exiting.${NC}"
    exit 1
fi
echo -e "\n${G}Authentication successful.${NC}"

#------------------------------------------------------
# System Configuration
echo -e "\n${Y}Configuring system...${NC}"

# Dark Mode
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-prussiangreen-dark'

# Terminal Colors - Namibian Flag (Blue/Red/Green on Black)
PROFILE_ID=$(dconf list /org/gnome/terminal/legacy/profiles:/ | grep '^:' | head -n 1 | tr -d ':/')
if [ -n "$PROFILE_ID" ]; then
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/background-color "'rgb(0,0,0)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/foreground-color "'rgb(0,154,68)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/bold-color "'rgb(210,16,52)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/use-theme-colors false
    echo -e "${G}Terminal colors configured with Namibian flag colors.${NC}"
fi

#------------------------------------------------------
# Package Management (Basic Updates)
echo -e "\n${Y}Updating system packages...${NC}"
echo "$sudoPW" | sudo -S apt-get update
echo "$sudoPW" | sudo -S apt-get upgrade -y

#------------------------------------------------------
# VSCodium AppImage Installation
echo -e "\n${Y}Setting up VSCodium AppImage...${NC}"

# Create essential directories
mkdir -p "${INSTALL_DIR}/Applications"
mkdir -p "${DESKTOP_FILE_DEST_DIR}"

# Download VSCodium AppImage
CODIUM_URL="https://github.com/VSCodium/vscodium/releases/latest/download/VSCodium-$(uname -m).AppImage"
echo -e "${Y}Downloading VSCodium...${NC}"
wget -O "${INSTALL_DIR}/Applications/VSCodium.AppImage" "$CODIUM_URL"

# Make executable
chmod +x "${INSTALL_DIR}/Applications/VSCodium.AppImage"

# Download icon
wget -O "${INSTALL_DIR}/Applications/vscodium.png" "https://github.com/VSCodium/vscodium/raw/master/src/resources/linux/codium.png"

# Create desktop entry
cat > "${DESKTOP_FILE_DEST_DIR}/vscodium.desktop" << EOF
[Desktop Entry]
Name=VSCodium
Comment=Open Source VS Code
Exec=${INSTALL_DIR}/Applications/VSCodium.AppImage
Icon=${INSTALL_DIR}/Applications/vscodium.png
Terminal=false
Type=Application
Categories=Development;
StartupWMClass=VSCodium
EOF

# Setup persistence
if [ -d "/live/persistence/TailsData_unlocked" ]; then
    mkdir -p "/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications"
    cp "${DESKTOP_FILE_DEST_DIR}/vscodium.desktop" "/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/"
    echo -e "${G}VSCodium will persist across reboots.${NC}"
fi

#------------------------------------------------------
# SovereignKey Shortcut Creation
echo -e "\n${Y}Creating SovereignKey shortcut...${NC}"

# Copy logo if exists
[ -f "${LOGO_SOURCE_PATH}" ] && cp "${LOGO_SOURCE_PATH}" "${LOGO_DEST_PATH}"

# Create .desktop file
cat > "${START_DIR}/temp.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=SovereignKey
Comment=SovereignKey Configuration Tool
Exec=${START_DIR}/sk.sh
Icon=${LOGO_DEST_PATH:-utilities-terminal}
Terminal=true
Type=Application
Categories=Utility;
EOF

# Install shortcut
mv "${START_DIR}/temp.desktop" "${DESKTOP_FILE_DEST_DIR}/${DESKTOP_FILE_NAME}"

#------------------------------------------------------
# Completion
echo -e "\n${G}=== Setup Complete ===${NC}"
echo -e "${Y}System features:${NC}"
echo "- Namibian terminal theme"
echo "- VSCodium AppImage installed to ${INSTALL_DIR}/Applications"
echo "- Desktop shortcuts created"
echo -e "\n${Y}Remember to:${NC}"
echo "1. Enable 'Dotfiles' in Persistent Storage"
echo "2. Make sk.sh executable: chmod +x sk.sh"
echo "3. Restart Tails for all changes to take effect"