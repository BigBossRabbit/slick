#!/bin/bash

<<<<<<< HEAD
# Script for TailsOS Persistent Storage configuration
# Installs SovereignKey features and configures system theme
=======
# Script is used to install some of the SovereignKey features
>>>>>>> 1e98e5c8c5d53737351c350ba0b91bee962870d1

#------------------------------------------------------
# Constants
PERSISTENCE_DIR="/home/amnesia/Persistent"
INSTALL_DIR="${PERSISTENCE_DIR}/SK"
SUDO_TIMEOUT=300  # 5 minutes sudo timeout

<<<<<<< HEAD
# ANSI Color codes
readonly Y="\033[1;33m"    # Yellow
readonly G="\033[0;32m"    # Green
readonly LB="\033[1;34m"   # Light Blue
readonly LR="\033[1;31m"   # Light Red
readonly NC="\033[0m"      # No Color

#------------------------------------------------------
# Functions
error_exit() {
    echo -e "${LR}Error: $1${NC}" >&2
    exit 1
}

check_persistence() {
    if [ ! -d "$PERSISTENCE_DIR" ]; then
        error_exit "Persistent Storage not enabled. Please enable it in Tails Configuration."
    fi
}

confirm_installation() {
    echo -e "${Y}This script will configure TailsOS system-wide theme and perform system updates.${NC}"
    echo -e "${LB}The following changes will be made:${NC}"
    echo "- Switch to System-Wide Dark Mode"
    echo "- Configure Terminal colors"
    echo "- Update system packages"
    echo "- Install VSCodium"
    echo
    echo -e "${LR}Press ${NC}<enter>${LR} to continue, or ${NC}ctrl-c${LR} to exit${NC}"
    read -r || error_exit "User input failed"
}

get_sudo_password() {
    echo -e "${Y}Enter sudo password once to reuse throughout the script...${NC}"
    read -r -s -p "Enter password for sudo: " SUDO_PASS
    echo
    
    # Verify sudo password
    if ! echo "$SUDO_PASS" | sudo -S true 2>/dev/null; then
        error_exit "Invalid sudo password"
    fi
    
    # Set sudo timeout
    echo "$SUDO_PASS" | sudo -S sh -c "echo 'Defaults timestamp_timeout=$SUDO_TIMEOUT' > /etc/sudoers.d/timeout"
    
    echo -e "${G}Password validated successfully.${NC}"
}

run_sudo_command() {
    echo "$SUDO_PASS" | sudo -S "$@" || error_exit "Failed to execute: $*"
}

setup_dark_theme() {
    echo -e "${Y}Configuring dark theme...${NC}"
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark || error_exit "Failed to set dark mode"
    gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-prussiangreen-dark' || error_exit "Failed to set GTK theme"
}
=======
# config
USER="amnesia"
START_DIR="/home/${USER}/Persistent"
INSTALL_DIR="${START_DIR}/SK"

#------------------------------------------------------
# bash colors
Y="\033[1;33m"    # is Yellow's ANSI color code
G="\033[0;32m"    # is Green's ANSI color code
LB="\033[1;34m"   # is L-Brown's ANSI color code
LR="\033[1;31m"   # is L-Red's ANSI color code
NC="\033[0m"      # No Color
#------------------------------------------------------

# fail if a command fails and exit
set -e

# clear screen
clear

#------------------------------------------------------

#
### Check if user really wants to install...or exit
#
echo
echo -e "${Y}This script will switch the default system-wide theme & run updates as well as upgrades to the system with this one simple script...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Switch the System-Wide theme to Dark Mode"
echo "- Install & update apt list"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r
>>>>>>> 1e98e5c8c5d53737351c350ba0b91bee962870d1

configure_terminal() {
    # Get default profile UUID
    local PROFILE_ID
    PROFILE_ID=$(dconf list /org/gnome/terminal/legacy/profiles:/ | grep '^:' | head -n 1 | tr -d ':/')
    
    if [ -z "$PROFILE_ID" ]; then
        error_exit "Could not retrieve GNOME Terminal profile ID"
    }

    # Configure terminal colors
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/background-color "'rgb(0,0,0)'" || error_exit "Failed to set terminal background"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/foreground-color "'rgb(0,255,0)'" || error_exit "Failed to set terminal foreground"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/use-theme-colors "false" || error_exit "Failed to set terminal theme"

<<<<<<< HEAD
    # Configure .bashrc
    if [ ! -f "${PERSISTENCE_DIR}/.bashrc" ]; then
        touch "${PERSISTENCE_DIR}/.bashrc"
    fi

    # Add terminal color settings if not already present
    if ! grep -q "TERM_COLORS" "${PERSISTENCE_DIR}/.bashrc"; then
        cat >> "${PERSISTENCE_DIR}/.bashrc" << 'EOF'
# TERM_COLORS
if [ "$TERM" = "xterm-256color" ]; then
    printf '\033]10;#00FF00\007\033]11;#000000\007'
fi
EOF
    fi
}

update_system() {
    echo -e "${Y}Updating system packages...${NC}"
    run_sudo_command apt-get update
    run_sudo_command apt-get upgrade -y
}

install_vscodium() {
    echo -e "${Y}Installing VSCodium...${NC}"
    
    # Add VSCodium repository key
    wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
        | gpg --dearmor \
        | run_sudo_command dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg

    # Add VSCodium repository
    echo 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg] https://download.vscodium.com/debs vscodium main' \
        | run_sudo_command tee /etc/apt/sources.list.d/vscodium.list

    # Install VSCodium
    run_sudo_command apt-get update
    run_sudo_command apt-get install -y codium
}

cleanup() {
    # Remove sudo timeout configuration
    if [ -n "$SUDO_PASS" ]; then
        echo "$SUDO_PASS" | sudo -S rm -f /etc/sudoers.d/timeout
    fi
}

#------------------------------------------------------
# Main execution
main() {
    clear
    check_persistence
    get_sudo_password
    confirm_installation
    setup_dark_theme
    configure_terminal
    update_system
    install_vscodium
    cleanup
    echo -e "${G}Configuration completed successfully!${NC}"
}

# Execute main with error handling and cleanup on exit
trap cleanup EXIT
main || error_exit "Script execution failed"
=======
#-----------------------------------------------------------------

# Enter sudo password once and reuse it later when needed
echo
echo -e "${Y}Enter sudo password once and reuse it later when needed...${NC}"
read -r -s -p "Enter password for sudo:" sudoPW
echo -e "\n${G}Password Accepted.${NC}"

#-----------------------------------------------------------------

# Command for System-Wide Dark Mode to be activated
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

# and change the gtk-theme
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-prussiangreen-dark'

# Setting Dark Mode for Terminal with Green Text

# Get the default profile UUID
PROFILE_ID=$(dconf list /org/gnome/terminal/legacy/profiles:/ | grep '^:' | head -n 1 | tr -d ':/')

if [ -z "$PROFILE_ID" ]; then
	echo "Error: Could not retrieve GNOME Terminal profile ID."
	exit 1
fi

#Apply the color changes
dconf write /org/gnome/Terminal/Legacy/Profile:/org/gnome/terminal/profiles:/:$PROFILE_ID/background-color "'rgb(0,0,0)'"
dconf write /org/gnome/Terminal/Legacy/Profile:/org/gnome/terminal/profiles:/:$PROFILE_ID/foreground-color "'rgb(0,255,0)'"
dconf write /org/gnome/Terminal/Legacy/Profile:/org/gnome/terminal/profiles:/:$PROFILE_ID/use-theme-colors false

echo "Persistent terminal colors set using dconf (green on black)."

# Ensure ~/.bashrc exists and add Permanent ANSI Escape Code
if [ ! -f ~/.bashrc ]; then
	touch ~/.bashrc
	echo "Created ~/.bashrc."
fi

# Define the color change command
COLOR_CMD='echo -e "\033]10;#00FF00\007\033]11;#000000\007"'

# Check if the command is already in .bashrc to avoid duplicates
if ! grep -qF "$COLOR_CMD" ~/.bashrc; then
	echo "$COLOR_CMD" >> ~/.bashrc
	echo "Terminal colors set to green on black and added to .bashrc"
else
	echo "Color settings already exist in .bashrc."
fi

#Apply changes immediately 

eval "$COLOR_CMD" 

echo "All changes applied successfully"

# Finally set the current mode to "dark"
echo "Dark Mode Activated"

#------------------------------------------------------
# Run apt update & upgrade
echo
echo -e "${Y}Update and upgrade of apt list...${NC}"
echo "$sudoPW" | sudo -S apt-get update
echo "$sudoPW" | sudo -S apt-get upgrade -y
echo -e "${G}Process Completed Successfully.${NC}"
echo -e "${Y}You are all set to go!${NC}"

#------------------------------------------------------
# VSCodium Installation Instructions (Debian/Ubuntu)
#------------------------------------------------------
# Add the GPG key of the repository:
 wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
     | gpg --dearmor \
     | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg

 Add the repository:
 echo 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg] https://download.vscodium.com/debs vscodium main' \
     | sudo tee /etc/apt/sources.list.d/vscodium.list

# Update then install vscodium:
 sudo apt update && sudo apt install codium
#------------------------------------------------------
>>>>>>> 1e98e5c8c5d53737351c350ba0b91bee962870d1
