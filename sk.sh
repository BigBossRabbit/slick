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
echo "3. Install Visual Studio Codium (Official)"
echo "4. Create application shortcut"
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
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/foreground-color "'rgb(0,154,68)'" # Green
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/bold-color "'rgb(210,16,52)'" # Red
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/use-theme-colors false
    echo -e "${G}Terminal colors configured with Namibian flag colors.${NC}"
fi

#------------------------------------------------------
# Package Management
echo -e "\n${Y}Updating system packages...${NC}"
echo "$sudoPW" | sudo -S apt-get update
echo "$sudoPW" | sudo -S apt-get upgrade -y

#------------------------------------------------------
# Visual Studio Codium Installation (Official)
echo -e "\n${Y}Installing Visual Studio Codium...${NC}"

# Install required dependencies
echo "$sudoPW" | sudo -S apt-get install -y wget

# Download and install from official GitHub releases
CODIUM_URL="https://github.com/VSCodium/vscodium/releases/latest/download/codium_$(dpkg --print-architecture).deb"
TEMP_DEB="/tmp/codium.deb"

wget -O "$TEMP_DEB" "$CODIUM_URL"
echo "$sudoPW" | sudo -S dpkg -i "$TEMP_DEB"
echo "$sudoPW" | sudo -S apt-get install -f -y  # Fix dependencies
rm "$TEMP_DEB"

# Create persistence config
if [ -d "/live/persistence/TailsData_unlocked" ]; then
    mkdir -p "/live/persistence/TailsData_unlocked/dotfiles/.config/VSCodium"
    echo -e "${G}VSCodium config will persist across reboots.${NC}"
fi

#------------------------------------------------------
# Create Application Shortcut
echo -e "\n${Y}Creating application shortcut...${NC}"

# Create directory structure
mkdir -p "${INSTALL_DIR}"
[ -f "${LOGO_SOURCE_PATH" ] && cp "${LOGO_SOURCE_PATH}" "${LOGO_DEST_PATH}"

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
mkdir -p "${DESKTOP_FILE_DEST_DIR}"
mv "${START_DIR}/temp.desktop" "${DESKTOP_FILE_DEST_DIR}/${DESKTOP_FILE_NAME}"

#------------------------------------------------------
# Completion
echo -e "\n${G}=== Setup Complete ===${NC}"
echo -e "Terminal now features ${Y}Namibia's colors${NC} (${LR}red${NC}, ${G}green${NC}, ${LB}blue${NC}) on black background"
echo -e "${Y}Visual Studio Codium (Official) is now installed${NC}"
echo -e "${Y}Shortcut will be available after restarting Tails.${NC}"
echo -e "${Y}Remember to enable 'Dotfiles' in Persistent Storage.${NC}"