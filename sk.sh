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

# Error handler
error_exit() {
    echo -e "${LR}ERROR: $1${NC}"
    exit 1
}

#------------------------------------------------------
# Verify Requirements
echo -e "${Y}=== Verifying Requirements ===${NC}"

# Internet check
echo -e "${Y}Checking internet...${NC}"
if ! wget -q --spider https://github.com; then
    error_exit "No internet connection"
fi

# Storage check
echo -e "${Y}Checking storage...${NC}"
MIN_SPACE=500000 # 500MB
AVAIL_SPACE=$(df "$START_DIR" | awk 'NR==2 {print $4}')
if [ "$AVAIL_SPACE" -lt "$MIN_SPACE" ]; then
    error_exit "Need 500MB free space"
fi

#------------------------------------------------------
# User Confirmation
echo -e "\n${Y}This script will:${NC}"
echo "1. Configure dark mode"
echo "2. Set terminal colors"
echo "3. Install VSCodium"
echo "4. Create shortcuts"
echo -e "\n${LR}Press Enter to continue or Ctrl+C to cancel${NC}"
read -r

#------------------------------------------------------
# Sudo Setup
echo -e "\n${Y}Enter sudo password:${NC}"
read -r -s -p "Password: " sudoPW
if ! echo "$sudoPW" | sudo -S -v; then
    error_exit "Invalid password"
fi
echo -e "\n${G}✓ Authenticated${NC}"

#------------------------------------------------------
# System Configuration
echo -e "\n${Y}=== Configuring System ===${NC}"

# Dark Mode
gsettings set org.gnome.desktop.interface color-scheme prefer-dark || echo -e "${Y}⚠ Couldn't set dark mode${NC}"
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-prussiangreen-dark' || echo -e "${Y}⚠ Couldn't set theme${NC}"

# Terminal Colors
PROFILE_ID=$(dconf list /org/gnome/terminal/legacy/profiles:/ | grep '^:' | head -n 1 | tr -d ':/')
if [ -n "$PROFILE_ID" ]; then
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/background-color "'rgb(0,0,0)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/foreground-color "'rgb(0,154,68)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/bold-color "'rgb(210,16,52)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/use-theme-colors false
    echo -e "${G}✓ Terminal colors set${NC}"
else
    echo -e "${Y}⚠ Couldn't configure terminal${NC}"
fi

#------------------------------------------------------
# VSCodium Installation
echo -e "\n${Y}=== Installing VSCodium ===${NC}"

# Create directory
mkdir -p "${INSTALL_DIR}/Applications" || error_exit "Failed to create directory"

# Download AppImage
echo -e "${Y}Downloading VSCodium...${NC}"
CODIUM_URL="https://github.com/VSCodium/vscodium/releases/latest/download/VSCodium-$(uname -m).AppImage"
if ! wget --show-progress -O "${INSTALL_DIR}/Applications/VSCodium.AppImage" "$CODIUM_URL"; then
    error_exit "Download failed"
fi

# Verify and set permissions
[ -s "${INSTALL_DIR}/Applications/VSCodium.AppImage" ] || error_exit "Download corrupted"
chmod +x "${INSTALL_DIR}/Applications/VSCodium.AppImage" || error_exit "Permission error"

# Download icon
wget -O "${INSTALL_DIR}/Applications/vscodium.png" "https://github.com/VSCodium/vscodium/raw/master/src/resources/linux/codium.png" || echo -e "${Y}⚠ Couldn't download icon${NC}"

# Create desktop file
cat > "/tmp/vscodium.desktop" << EOF
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

mkdir -p "${DESKTOP_FILE_DEST_DIR}"
mv "/tmp/vscodium.desktop" "${DESKTOP_FILE_DEST_DIR}/" || echo -e "${Y}⚠ Couldn't create desktop file${NC}"

# Setup persistence
if [ -d "/live/persistence/TailsData_unlocked" ]; then
    mkdir -p "/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications"
    cp "${DESKTOP_FILE_DEST_DIR}/vscodium.desktop" "/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/" || echo -e "${Y}⚠ Couldn't setup persistence${NC}"
fi

#------------------------------------------------------
# Create Shortcut
echo -e "\n${Y}Creating shortcut...${NC}"
[ -f "${LOGO_SOURCE_PATH}" ] && cp "${LOGO_SOURCE_PATH}" "${LOGO_DEST_PATH}"

cat > "/tmp/sovereignkey.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=SovereignKey
Comment=Configuration Tool
Exec=${START_DIR}/sk.sh
Icon=${LOGO_DEST_PATH:-utilities-terminal}
Terminal=true
Type=Application
Categories=Utility;
EOF

mv "/tmp/sovereignkey.desktop" "${DESKTOP_FILE_DEST_DIR}/${DESKTOP_FILE_NAME}" || error_exit "Shortcut creation failed"

#------------------------------------------------------
echo -e "\n${G}=== INSTALLATION COMPLETE ===${NC}"
echo -e "${Y}VSCodium installed to:${NC}"
echo "${INSTALL_DIR}/Applications/VSCodium.AppImage"
echo -e "\n${Y}Restart Tails and enable 'Dotfiles' persistence${NC}"