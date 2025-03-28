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
LOG_FILE="${START_DIR}/sk_install.log"

#------------------------------------------------------
# Colors
Y="\033[1;33m"    # Yellow
G="\033[0;32m"    # Green
LR="\033[1;31m"   # Light Red
NC="\033[0m"      # No Color

#------------------------------------------------------
# Initial Setup
clear
echo "" > "$LOG_FILE"
echo -e "${Y}=== SovereignKey Setup for TailsOS ===${NC}" | tee -a "$LOG_FILE"
echo "Installation log: $LOG_FILE"

# Error handler function
error_exit() {
    echo -e "${LR}ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

#------------------------------------------------------
# Verify Requirements
echo -e "\n${Y}=== Verifying Requirements ===${NC}" | tee -a "$LOG_FILE"

# Internet check
echo -e "${Y}Checking internet connection...${NC}" | tee -a "$LOG_FILE"
if ! wget -q --spider https://github.com; then
    error_exit "No internet connection detected"
fi

# Storage check
echo -e "${Y}Checking available storage...${NC}" | tee -a "$LOG_FILE"
MIN_SPACE=500000 # 500MB
AVAIL_SPACE=$(df "$START_DIR" | awk 'NR==2 {print $4}')
if [ "$AVAIL_SPACE" -lt "$MIN_SPACE" ]; then
    error_exit "Insufficient disk space (requires at least 500MB free)"
fi

#------------------------------------------------------
# User Confirmation
echo -e "\n${Y}This script will:${NC}" | tee -a "$LOG_FILE"
echo "1. Configure system theme (Dark Mode)" | tee -a "$LOG_FILE"
echo "2. Set terminal colors (Namibian flag colors)" | tee -a "$LOG_FILE"
echo "3. Install Visual Studio Codium (AppImage)" | tee -a "$LOG_FILE"
echo "4. Create application shortcut(s)" | tee -a "$LOG_FILE"
echo -e "\n${LR}Press Enter to continue or Ctrl+C to cancel${NC}"
read -r

#------------------------------------------------------
# Begin Installation
(
#------------------------------------------------------
# Sudo Setup
echo -e "\n${Y}=== Setting Up Sudo ===${NC}" | tee -a "$LOG_FILE"
echo -e "${Y}Enter sudo password:${NC}"
read -r -s -p "Password: " sudoPW
if ! echo "$sudoPW" | sudo -S -v 2>> "$LOG_FILE"; then
    error_exit "Invalid sudo password"
fi
echo -e "\n${G}Authentication successful.${NC}" | tee -a "$LOG_FILE"

#------------------------------------------------------
# System Configuration
echo -e "\n${Y}=== Configuring System ===${NC}" | tee -a "$LOG_FILE"

# Dark Mode
if ! gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>> "$LOG_FILE"; then
    echo -e "${Y}Warning: Could not set dark mode${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${G}✓ Dark mode enabled${NC}" | tee -a "$LOG_FILE"
fi

# Terminal Colors
PROFILE_ID=$(dconf list /org/gnome/terminal/legacy/profiles:/ | grep '^:' | head -n 1 | tr -d ':/')
if [ -n "$PROFILE_ID" ]; then
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/background-color "'rgb(0,0,0)'" 2>> "$LOG_FILE"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/foreground-color "'rgb(0,154,68)'" 2>> "$LOG_FILE"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/bold-color "'rgb(210,16,52)'" 2>> "$LOG_FILE"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/use-theme-colors false 2>> "$LOG_FILE"
    echo -e "${G}✓ Terminal colors configured${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${Y}Warning: Could not configure terminal colors${NC}" | tee -a "$LOG_FILE"
fi

#------------------------------------------------------
# Package Updates
echo -e "\n${Y}=== Updating System ===${NC}" | tee -a "$LOG_FILE"
echo "$sudoPW" | sudo -S apt-get update 2>> "$LOG_FILE"
echo "$sudoPW" | sudo -S apt-get upgrade -y 2>> "$LOG_FILE"
echo -e "${G}✓ System updated${NC}" | tee -a "$LOG_FILE"

#------------------------------------------------------
# VSCodium Installation
echo -e "\n${Y}=== Installing VSCodium ===${NC}" | tee -a "$LOG_FILE"

# Create directory structure
mkdir -p "${INSTALL_DIR}/Applications" 2>> "$LOG_FILE" || error_exit "Failed to create Applications directory"

# Download VSCodium
echo -e "${Y}Downloading VSCodium AppImage...${NC}" | tee -a "$LOG_FILE"
CODIUM_URL="https://github.com/VSCodium/vscodium/releases/latest/download/VSCodium-$(uname -m).AppImage"
if ! wget --show-progress -O "${INSTALL_DIR}/Applications/VSCodium.AppImage" "$CODIUM_URL" 2>> "$LOG_FILE"; then
    error_exit "Download failed"
fi

# Verify download
if [ ! -s "${INSTALL_DIR}/Applications/VSCodium.AppImage" ]; then
    error_exit "Downloaded file is empty or corrupted"
fi
echo -e "${G}✓ VSCodium downloaded successfully${NC}" | tee -a "$LOG_FILE"

# Set permissions
chmod +x "${INSTALL_DIR}/Applications/VSCodium.AppImage" 2>> "$LOG_FILE" || error_exit "Could not make AppImage executable"

# Download icon
wget -O "${INSTALL_DIR}/Applications/vscodium.png" "https://github.com/VSCodium/vscodium/raw/master/src/resources/linux/codium.png" 2>> "$LOG_FILE"

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

mkdir -p "${DESKTOP_FILE_DEST_DIR}" 2>> "$LOG_FILE"
mv "/tmp/vscodium.desktop" "${DESKTOP_FILE_DEST_DIR}/vscodium.desktop" 2>> "$LOG_FILE"
echo -e "${G}✓ VSCodium desktop entry created${NC}" | tee -a "$LOG_FILE"

# Setup persistence
if [ -d "/live/persistence/TailsData_unlocked" ]; then
    mkdir -p "/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications" 2>> "$LOG_FILE"
    cp "${DESKTOP_FILE_DEST_DIR}/vscodium.desktop" "/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/" 2>> "$LOG_FILE"
    echo -e "${G}✓ Persistent VSCodium configuration created${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${Y}Warning: Persistence not enabled - settings won't survive reboot${NC}" | tee -a "$LOG_FILE"
fi

#------------------------------------------------------
# SovereignKey Shortcut
echo -e "\n${Y}=== Creating Shortcuts ===${NC}" | tee -a "$LOG_FILE"

if [ -f "${LOGO_SOURCE_PATH}" ]; then
    cp "${LOGO_SOURCE_PATH}" "${LOGO_DEST_PATH}" 2>> "$LOG_FILE"
fi

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

mv "/tmp/sovereignkey.desktop" "${DESKTOP_FILE_DEST_DIR}/${DESKTOP_FILE_NAME}" 2>> "$LOG_FILE"
echo -e "${G}✓ SovereignKey shortcut created${NC}" | tee -a "$LOG_FILE"

#------------------------------------------------------
# Finish
echo -e "\n${G}=== INSTALLATION COMPLETE ===${NC}" | tee -a "$LOG_FILE"
echo -e "${Y}VSCodium is installed at:${NC}" | tee -a "$LOG_FILE"
echo "${INSTALL_DIR}/Applications/VSCodium.AppImage" | tee -a "$LOG_FILE"
echo -e "\n${Y}To complete setup:${NC}" | tee -a "$LOG_FILE"
echo "1. Enable 'Dotfiles' persistence when rebooting Tails" | tee -a "$LOG_FILE"
echo "2. Run 'chmod +x sk.sh' to make script executable" | tee -a "$LOG_FILE"

exit 0
) >> "$LOG_FILE" 2>&1

# Exit with appropriate status
if [ $? -eq 0 ]; then
    echo -e "\n${G}Installation completed successfully!${NC}"
    echo -e "Detailed log: $LOG_FILE"
    exit 0
else
    echo -e "\n${LR}Installation failed - please check $LOG_FILE${NC}"
    exit 1
fi