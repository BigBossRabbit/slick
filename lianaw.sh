#!/bin/bash
# lianaw.sh - Install Liana Wallet on TailsOS with persistence
# Uses pre-built Linux binary instead of building from source

# Color codes for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "\n${GREEN}=== Liana Wallet Installation Script for Tails OS ===${NC}\n"

# Check if running in Tails
if [ ! -d "/live/persistence" ]; then
    echo -e "${RED}Error: This script must be run in Tails OS${NC}"
    exit 1
fi

# Check if persistence is enabled
if [ ! -d "/live/persistence/TailsData_unlocked" ]; then
    echo -e "${RED}Error: Tails persistence must be enabled and unlocked${NC}"
    exit 1
fi

# Define persistent directories
PERSISTENT_DIR="/home/amnesia/Persistent"
LIANA_DIR="$PERSISTENT_DIR/liana"
DOT_LOCAL="$PERSISTENT_DIR/.local"
DOT_CONFIG="$PERSISTENT_DIR/.config"

# Create required directories
mkdir -p "$LIANA_DIR"
mkdir -p "$DOT_LOCAL/share/applications"
mkdir -p "$DOT_CONFIG"

# Download latest Liana release
echo -e "${YELLOW}Downloading Liana...${NC}"
LIANA_VERSION="v0.3.1"  # Update this as needed
LIANA_URL="https://github.com/wizardsardine/liana/releases/download/${LIANA_VERSION}/liana-${LIANA_VERSION}-x86_64-linux-gnu.tar.gz"

# Download and extract Liana
cd "$LIANA_DIR"
wget "$LIANA_URL" -O liana.tar.gz
tar xzf liana.tar.gz
rm liana.tar.gz

# Create a script that will be used to launch Liana
cat > "$LIANA_DIR/start-liana.sh" << 'INNEREOF'
#!/bin/bash
cd "/home/amnesia/Persistent/liana"
./liana-gui
INNEREOF

chmod +x "$LIANA_DIR/start-liana.sh"

# Create desktop entry
cat > "$DOT_LOCAL/share/applications/liana.desktop" << 'INNEREOF'
[Desktop Entry]
Version=1.0
Name=Liana Wallet
Exec=/home/amnesia/Persistent/liana/start-liana.sh
Icon=/home/amnesia/Persistent/liana/logo.png
Terminal=false
Type=Application
Categories=Network;Finance;
Comment=Bitcoin wallet with inheritance features
INNEREOF

# Create symlinks for persistence
ln -sf "$DOT_LOCAL" "$HOME/.local"
ln -sf "$DOT_CONFIG" "$HOME/.config"

# Print success message and instructions
echo -e "\n${GREEN}=== Installation Complete ===${NC}"
echo -e "${YELLOW}Important Post-Install Steps:${NC}"
echo "1. Make sure you have enabled persistence for:"
echo "   - Personal Data"
echo "   - Dotfiles"
echo -e "\n2. After each Tails restart:"
echo "   - Unlock your persistent volume"
echo "   - Liana will be available in the Applications menu"
echo -e "\n${GREEN}Liana Wallet has been installed successfully!${NC}"
