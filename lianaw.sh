#!/bin/bash
# lianaw.sh - Install Liana Wallet on TailsOS with persistence
# Based on successful persistence patterns from BtcAutoNode's SeedSigner script

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

# Create a script that will be used to launch Liana
cat > "$LIANA_DIR/start-liana.sh" << 'INNEREOF'
#!/bin/bash
export PATH="/home/amnesia/Persistent/liana/cargo/bin:$PATH"
export CARGO_HOME="/home/amnesia/Persistent/liana/cargo"
export RUSTUP_HOME="/home/amnesia/Persistent/liana/rustup"
cd "/home/amnesia/Persistent/liana/liana-src"
./target/release/liana-gui
INNEREOF

chmod +x "$LIANA_DIR/start-liana.sh"

# Install build dependencies
echo -e "${YELLOW}Installing build dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    libssl-dev \
    pkg-config \
    cmake \
    libgtk-3-dev \
    libclang-dev \
    git \
    curl

# Install Rust with custom paths for persistence
echo -e "${YELLOW}Installing Rust...${NC}"
export CARGO_HOME="$LIANA_DIR/cargo"
export RUSTUP_HOME="$LIANA_DIR/rustup"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

# Source the new Rust environment
source "$CARGO_HOME/env"

# Clone and build Liana
echo -e "${YELLOW}Cloning and building Liana...${NC}"
if [ ! -d "$LIANA_DIR/liana-src" ]; then
    git clone https://github.com/wizardsardine/liana.git "$LIANA_DIR/liana-src"
fi
cd "$LIANA_DIR/liana-src"
cargo build --release --bin liana-gui

# Create desktop entry
cat > "$DOT_LOCAL/share/applications/liana.desktop" << 'INNEREOF'
[Desktop Entry]
Version=1.0
Name=Liana Wallet
Exec=/home/amnesia/Persistent/liana/start-liana.sh
Icon=/home/amnesia/Persistent/liana/liana-src/gui/assets/logo.png
Terminal=false
Type=Application
Categories=Network;Finance;
Comment=Bitcoin wallet with inheritance features
