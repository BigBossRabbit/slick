#!/bin/bash
# lianaw.sh - Install Liana Wallet on TailsOS with persistence

set -euo pipefail  # Exit on error, undefined vars, pipe failures
set -x  # Enables debug output showing commands

trap 'echo "[ERROR] Error on line $LINENO: $BASH_COMMAND with exit code $?" >&2' ERR

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "\n${GREEN}=== Liana Wallet Installation Script for Tails OS ===${NC}\n"

# Better Tails detection
if ! grep -q "TAILS" /etc/os-release 2>/dev/null; then
    error "This script must be run in Tails OS"
fi

# Check if persistence is available (more robust check)
if [ ! -d "/live/persistence" ] && [ ! -d "/home/amnesia/Persistent" ]; then
    error "Tails persistence must be enabled and unlocked"
fi

# Define directories
PERSISTENT_DIR="/home/amnesia/Persistent"
LIANA_DIR="$PERSISTENT_DIR/liana"
DOT_LOCAL="$PERSISTENT_DIR/.local"
DOT_CONFIG="$PERSISTENT_DIR/.config"

# Create directories
log "Creating directories..."
mkdir -p "$LIANA_DIR" "$DOT_LOCAL/share/applications" "$DOT_CONFIG"

# Fetch latest version dynamically
log "Fetching latest Liana version..."
LIANA_VERSION=$(curl -s https://api.github.com/repos/wizardsardine/liana/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
LIANA_VERSION_CLEAN=${LIANA_VERSION#v}  # Remove leading 'v'
LIANA_URL="https://github.com/wizardsardine/liana/releases/download/${LIANA_VERSION}/liana-${LIANA_VERSION_CLEAN}-x86_64-linux-gnu.tar.gz"

# Download with error checking
log "Downloading Liana ${LIANA_VERSION}..."
cd "$LIANA_DIR"
if ! wget "$LIANA_URL" -O liana.tar.gz; then
    error "Failed to download Liana"
fi

# Extract with error checking
log "Extracting archive..."
if ! tar xzf liana.tar.gz; then
    error "Failed to extract archive"
fi
rm liana.tar.gz

# Make binary executable
chmod +x liana-*/liana-gui 2>/dev/null || warn "Could not set executable permissions"

# Create launcher script
cat > "$LIANA_DIR/start-liana.sh" << 'EOF'
#!/bin/bash
cd "/home/amnesia/Persistent/liana"
# Find the actual binary location
LIANA_BIN=$(find . -name "liana-gui" -type f 2>/dev/null | head -1)
if [ -n "$LIANA_BIN" ]; then
    exec "$LIANA_BIN"
else
    echo "Error: Could not find liana-gui binary"
    exit 1
fi
EOF
chmod +x "$LIANA_DIR/start-liana.sh"

# Handle existing symlinks/directories
for dir_pair in ".local:$DOT_LOCAL" ".config:$DOT_CONFIG"; do
    target_name=$(echo "$dir_pair" | cut -d: -f1)
    source_path=$(echo "$dir_pair" | cut -d: -f2)
    target_path="$HOME/$target_name"
    
    if [ -L "$target_path" ]; then
        rm "$target_path"
    elif [ -d "$target_path" ]; then
        warn "$target_path exists as directory, backing up..."
        mv "$target_path" "${target_path}.backup.$(date +%s)"
    fi
    ln -sf "$source_path" "$target_path"
done

# Create desktop entry (with fallback icon)
cat > "$DOT_LOCAL/share/applications/liana.desktop" << 'EOF'
[Desktop Entry]
Version=13.1
Name=Liana Wallet
Exec=/home/amnesia/Persistent/liana/start-liana.sh
Icon=/home/amnesia/Persistent/liana/
Terminal=false
Type=Application
Categories=Network;Finance;
Comment=Bitcoin wallet with inheritance features
EOF

log "Installation complete!"