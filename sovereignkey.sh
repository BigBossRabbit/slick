#!/bin/bash

# Script is used to install some of the SovereignKey features

#------------------------------------------------------

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

#-----------------------------------------------------------------

# clear screen
clear

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

if [ -z "PROFILE_ID" ]; then
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
