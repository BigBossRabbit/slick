#!/bin/bash

# SovereignKey Enhanced Setup Script to hide installation folder but show icon 

USER="amnesia"
START_DIR="/home/${USER}/Persistent"
INSTALL_DIR="${START_DIR}/.SKHidden"   # Hidden by prefixing with dot
LOGO_NAME="SKmedium.jpeg"
LOGO_SOURCE_PATH="${START_DIR}/${LOGO_NAME}"
LOGO_DEST_PATH="${INSTALL_DIR}/${LOGO_NAME}"
DESKTOP_FILE_NAME="SovereignKey.desktop"
DESKTOP_FILE_DEST_DIR="/home/${USER}/.local/share/applications"

# Colors
Y="\033[1;33m"    # Yellow
G="\033[0;32m"    # Green
LR="\033[1;31m"   # Light Red
NC="\033[0m"      # No Color

clear
echo -e "${Y}=== SovereignKey Setup (Hidden Install Folder) ===${NC}"
echo
echo -e "${Y}This script will:${NC}"
echo "1. Configure system theme (Dark Mode)"
echo "2. Set terminal colors (Namibian flag)"
echo "3. Create application shortcut for hidden install folder"
echo
echo -e "${LR}Press Enter to continue or Ctrl+C to cancel${NC}"
read -r

echo
echo -e "${Y}Enter sudo password:${NC}"
read -r -s -p "Password: " sudoPW
if ! echo "$sudoPW" | sudo -S -v; then
    echo -e "\n${LR}Invalid password. Exiting.${NC}"
    exit 1
fi
echo -e "\n${G}Authentication successful.${NC}"

echo -e "\n${Y}Configuring system...${NC}"
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-prussiangreen-dark'

PROFILE_ID=$(dconf list /org/gnome/terminal/legacy/profiles:/ | grep '^:' | head -n 1 | tr -d ':/')
if [ -n "$PROFILE_ID" ]; then
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/background-color "'rgb(0,0,0)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/foreground-color "'rgb(0,154,68)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/bold-color "'rgb(210,16,52)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/use-theme-colors false

    COLOR_CMD='echo -e "\033]10;#009A44\007\033]11;#000000\007\033]12;#D21034\007\033]13;#0033A0\007"'
    if ! grep -qF "$COLOR_CMD" ~/.bashrc; then
        echo "$COLOR_CMD" >> ~/.bashrc
    fi
    eval "$COLOR_CMD"
    echo -e "${G}Namibian flag colors applied instantly!${NC}"
fi

echo -e "\n${Y}Creating hidden installation folder and shortcut...${NC}"
mkdir -p "${INSTALL_DIR}"
if [ -f "${LOGO_SOURCE_PATH}" ]; then
    cp "${LOGO_SOURCE_PATH}" "${LOGO_DEST_PATH}"
fi

cat > "${START_DIR}/temp.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=SovereignKey
Comment=SovereignKey Configuration Tool
Exec=${INSTALL_DIR}/sk.sh
Icon=${LOGO_DEST_PATH}
Terminal=true
Type=Application
Categories=Utility;
EOF

mkdir -p "${DESKTOP_FILE_DEST_DIR}"
mv "${START_DIR}/temp.desktop" "${DESKTOP_FILE_DEST_DIR}/${DESKTOP_FILE_NAME}"

echo -e "\n${G}=== Setup Complete ===${NC}"
echo -e "Terminal features Namibia's colors"
echo -e "Shortcut available with visible icon despite hidden install folder"
echo -e "Enable 'Dotfiles' in Persistent Storage to see hidden folders"
