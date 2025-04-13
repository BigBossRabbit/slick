#!/bin/bash

# Script for TailsOS Persistent Storage configuration
# Installs SovereignKey features and configures system theme

#------------------------------------------------------
# Constants
PERSISTENCE_DIR="/home/amnesia/Persistent"
INSTALL_DIR="${PERSISTENCE_DIR}/SK"
SUDO_TIMEOUT=300  # 5 minutes sudo timeout

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