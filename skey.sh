#!/bin/bash

# Script is used to install some of the SovereignKey features and create an application shortcut

#------------------------------------------------------

# config
USER="amnesia"
START_DIR="/home/${USER}/Persistent"
INSTALL_DIR="${START_DIR}/SK" # Main directory for SK related files
LOGO_NAME="SKmedium.jpeg" # Logo filename provided by user
LOGO_SOURCE_PATH="${START_DIR}/${LOGO_NAME}" # Assuming logo is in Persistent dir with the script
LOGO_DEST_PATH="${INSTALL_DIR}/${LOGO_NAME}" # Destination for the logo within SK dir
DESKTOP_FILE_NAME="SovereignKey_Setup.desktop"
DESKTOP_FILE_DEST_DIR="/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications"
DESKTOP_FILE_DEST_PATH="${DESKTOP_FILE_DEST_DIR}/${DESKTOP_FILE_NAME}"
MAX_APT_RETRIES=6 # Number of times to retry apt commands if lock is held
APT_RETRY_DELAY=10 # Seconds to wait between retries

#------------------------------------------------------
# bash colors
Y="\033[1;33m"    # is Yellow's ANSI color code
G="\033[0;32m"    # is Green's ANSI color code
LB="\033[1;34m"   # is L-Brown's ANSI color code
LR="\033[1;31m"   # is L-Red's ANSI color code
NC="\033[0m"      # No Color
#------------------------------------------------------

# fail if a command fails and exit
# set -e # Temporarily disable set -e to handle apt lock checks gracefully

# clear screen
clear

#------------------------------------------------------

# Function to check if a command is available
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to run apt commands with lock checking and retries
# IMPORTANT: This function assumes $sudoPW is set globally in the script
run_apt_command() {
    local cmd_args=("$@")
    local retries=0
    while true; do
        # Check for the lock file being held using sudo directly (timestamp should allow this)
        # If sudo asks for password here repeatedly, the timestamp might be too short in Tails
        if sudo lsof /var/lib/dpkg/lock-frontend > /dev/null || sudo lsof /var/lib/apt/lists/lock > /dev/null || sudo lsof /var/cache/apt/archives/lock > /dev/null; then
            if [ $retries -ge $MAX_APT_RETRIES ]; then
                echo -e "${LR}Error: apt lock files are still held after $MAX_APT_RETRIES retries. Please ensure no other package managers are running and try again.${NC}"
                exit 1
            fi
            echo -e "${Y}Waiting for apt lock files to be released... (Retry $((retries + 1))/$MAX_APT_RETRIES)${NC}"
            sleep $APT_RETRY_DELAY
            retries=$((retries + 1))
        else
            # Attempt to run the command using the stored password
            echo "$sudoPW" | sudo -S "${cmd_args[@]}"
            local exit_code=$? # Capture exit code immediately

            if [ $exit_code -eq 0 ]; then
                break # Exit loop if command succeeds
            else
                 # Check if the failure was due to a lock error (e.g., exit code 100 for apt)
                 # or just retry regardless
                 if [ $retries -ge $MAX_APT_RETRIES ]; then
                    echo -e "${LR}Error: apt command failed after $MAX_APT_RETRIES retries with exit code $exit_code.${NC}"
                    # Consider adding more specific error handling based on exit codes if needed
                    exit 1
                 fi
                 echo -e "${Y}apt command failed (Exit Code: $exit_code), possibly due to a lock or other issue. Retrying... (Retry $((retries + 1))/$MAX_APT_RETRIES)${NC}"
                 sleep $APT_RETRY_DELAY
                 retries=$((retries + 1))
            fi
        fi
    done
}


# Check for required commands
REQUIRED_COMMANDS=("gsettings" "dconf" "grep" "tr" "apt-get" "mkdir" "cp" "mv" "lsof" "sleep")
for cmd in "${REQUIRED_COMMANDS[@]}"; do
  if ! command_exists "$cmd"; then
    echo -e "${LR}Error: Required command '$cmd' not found. Please ensure it is installed and in your PATH.${NC}"
    exit 1
  fi
done

#------------------------------------------------------

#
### Check if user really wants to install...or exit
#
echo
echo -e "${Y}This script will run updates/upgrades, switch the system theme, set terminal colors, and create an Application shortcut.${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Run apt update and upgrade (checking for locks)"
echo "- Switch the System-Wide theme to Dark Mode"
echo "- Set Terminal colors to Green on Black"
echo "- Create an Application menu shortcut for this script"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

# clear screen
clear

#-----------------------------------------------------------------

# Enter sudo password once and reuse it later when needed
echo
echo -e "${Y}Enter sudo password once and reuse it later when needed...${NC}"
read -r -s -p "Enter password for sudo:" sudoPW
# Validate sudo password immediately to avoid issues later
if ! echo "$sudoPW" | sudo -S -v; then
    echo -e "\n${LR}Invalid sudo password. Exiting.${NC}"
    exit 1
fi
echo -e "\n${G}Password Accepted.${NC}"


#-----------------------------------------------------------------

# Run apt update & upgrade FIRST, with lock checking
echo
echo -e "${Y}Running apt update and upgrade (will wait if locks are detected)...${NC}"
run_apt_command apt-get update
run_apt_command apt-get upgrade -y
echo -e "${G}System Update/Upgrade Process Completed Successfully.${NC}"

# Re-enable exit on error after apt commands
set -e

#-----------------------------------------------------------------
# Create SK directory if it doesn't exist
if [ ! -d "${INSTALL_DIR}" ]; then
    mkdir -p "${INSTALL_DIR}"
    echo -e "${G}Created directory: ${INSTALL_DIR}${NC}"
fi

# Copy logo file to INSTALL_DIR
if [ -f "${LOGO_SOURCE_PATH}" ]; then
    # Use sudo with password pipe for copying to potentially restricted areas if needed,
    # but INSTALL_DIR is likely user-owned. cp should work without sudo here.
    cp "${LOGO_SOURCE_PATH}" "${LOGO_DEST_PATH}"
    echo -e "${G}Copied logo to ${LOGO_DEST_PATH}${NC}"
else
    echo -e "${LR}Warning: Logo file ${LOGO_SOURCE_PATH} not found. Shortcut icon may not display correctly.${NC}"
    # Set a fallback generic icon path or leave it empty if logo is critical
    LOGO_DEST_PATH="/usr/share/icons/gnome/scalable/apps/utilities-terminal-symbolic.svg" # Example fallback
fi

#-----------------------------------------------------------------

# Command for System-Wide Dark Mode to be activated
echo -e "${Y}Setting System-Wide Dark Mode...${NC}"
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

# and change the gtk-theme
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-prussiangreen-dark'
echo -e "${G}Dark Mode Activated.${NC}"

#-----------------------------------------------------------------

# Setting Dark Mode for Terminal with Green Text
echo -e "${Y}Setting Terminal Colors (Green on Black)...${NC}"

# Get the default profile UUID
PROFILE_ID=$(dconf list /org/gnome/terminal/legacy/profiles:/ | grep '^:' | head -n 1 | tr -d ':/')

if [ -z "$PROFILE_ID" ]; then
    echo -e "${LR}Error: Could not retrieve GNOME Terminal profile ID.${NC}"
    # Don't exit, just skip terminal color setting
else
    # Apply the color changes using dconf
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/background-color "'rgb(0,0,0)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/foreground-color "'rgb(0,255,0)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/use-theme-colors false
    echo -e "${G}Persistent terminal colors set using dconf.${NC}"

    # Ensure ~/.bashrc exists and add Permanent ANSI Escape Code for immediate effect and future sessions
    if [ ! -f ~/.bashrc ]; then
        touch ~/.bashrc
        echo "Created ~/.bashrc."
    fi

    # Define the color change command
    COLOR_CMD='echo -e "\033]10;#00FF00\007\033]11;#000000\007"'

    # Check if the command is already in .bashrc to avoid duplicates
    if ! grep -qF "$COLOR_CMD" ~/.bashrc; then
        echo "$COLOR_CMD" >> ~/.bashrc
        echo -e "${G}Terminal color settings added to .bashrc for future sessions.${NC}"
    else
        echo "Color settings already exist in .bashrc."
    fi

    # Apply changes immediately for current session
    eval "$COLOR_CMD"
    echo -e "${G}Terminal colors applied to current session.${NC}"
fi

#-----------------------------------------------------------------

# Create Application Shortcut
echo -e "${Y}Creating Application Shortcut...${NC}"

# Create dotfiles directory structure if it doesn't exist
echo "$sudoPW" | sudo -S mkdir -p "${DESKTOP_FILE_DEST_DIR}"

# Create temporary .desktop file content
cat > "${START_DIR}/desktop_temp"<< EOF
[Desktop Entry]
Version=1.0
Name=SovereignKey Setup
Comment=Run the SovereignKey setup script (Dark Mode, Terminal Colors, Updates)
Exec=${START_DIR}/skey.sh
Icon=${LOGO_DEST_PATH}
Terminal=true
Type=Application
Categories=Utility;System;
EOF

# Move the temporary file to the final destination with sudo
echo "$sudoPW" | sudo -S mv "${START_DIR}/desktop_temp" "${DESKTOP_FILE_DEST_PATH}"
echo -e "${G}Application shortcut created. It will appear in the menu after the next Tails restart (ensure 'Dotfiles' persistence is enabled).${NC}"

#------------------------------------------------------

echo
echo -e "${G}--- SovereignKey Setup Complete ---${NC}"
echo -e "${Y}You are all set! Remember to enable 'Dotfiles' in Persistent Storage settings for the shortcut to appear.${NC}"
