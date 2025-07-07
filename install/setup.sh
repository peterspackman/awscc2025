#!/bin/bash

# AWSCC 2025 Workshop Setup Script
# Installs OCC from GitHub releases and sets up environment

set -e  # Exit on any error

WORKSHOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$WORKSHOP_DIR/bin"

echo "=== AWSCC 2025 Workshop Setup ==="
echo "Workshop directory: $WORKSHOP_DIR"
echo "Installing OCC to: $BIN_DIR"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
    "darwin")
        if [[ "$ARCH" == "arm64" ]]; then
            PLATFORM_SUFFIX="macos-arm64"
        else
            PLATFORM_SUFFIX="macos-x86_64"
        fi
        ;;
    "linux")
        if [[ "$ARCH" == "x86_64" ]]; then
            PLATFORM_SUFFIX="linux-x86_64-static"
        else
            echo "Unsupported Linux architecture: $ARCH"
            exit 1
        fi
        ;;
    *)
        echo "Unsupported OS: $OS"
        echo "Please use setup.ps1 for Windows or install manually"
        exit 1
        ;;
esac

echo "Detected platform: $PLATFORM_SUFFIX"

# Get latest release info from GitHub API
echo "Fetching latest OCC release information..."
LATEST_RELEASE=$(curl -s --max-time 30 https://api.github.com/repos/peterspackman/occ/releases/latest)
VERSION=$(echo "$LATEST_RELEASE" | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

if [[ -z "$VERSION" ]]; then
    echo "Failed to get latest version from GitHub API. Using fallback version..."
    # Fallback to a known working version
    VERSION="v0.7.6"
    echo "Using fallback OCC version: $VERSION"
fi

# Remove 'v' prefix from version if present
VERSION_NUM=${VERSION#v}

echo "OCC version: $VERSION"

# Construct download URL using actual format
ARCHIVE_NAME="occ-${VERSION_NUM}-${PLATFORM_SUFFIX}.tar.xz"
DOWNLOAD_URL="https://github.com/peterspackman/occ/releases/download/${VERSION}/${ARCHIVE_NAME}"

echo "Download URL: $DOWNLOAD_URL"

# Create directories
mkdir -p "$BIN_DIR"

# Check if OCC is already installed
if [[ -f "$BIN_DIR/occ" ]]; then
    echo "OCC already installed in $BIN_DIR, skipping download..."
else
    # Download and extract OCC
    echo "Downloading OCC..."
    cd "$WORKSHOP_DIR"
    curl -L "$DOWNLOAD_URL" -o "$ARCHIVE_NAME"

    echo "Extracting OCC..."
    tar -xf "$ARCHIVE_NAME"

    # Find the extracted files and move them appropriately
    EXTRACTED_DIR="occ-${VERSION_NUM}-${PLATFORM_SUFFIX}"

    if [[ -d "$EXTRACTED_DIR" ]]; then
        echo "Found extracted directory: $EXTRACTED_DIR"
        
        # Copy the executable
        if [[ -f "$EXTRACTED_DIR/bin/occ" ]]; then
            cp "$EXTRACTED_DIR/bin/occ" "$BIN_DIR/"
            echo "Copied OCC executable"
        else
            echo "Error: Could not find occ executable in $EXTRACTED_DIR/bin/"
            exit 1
        fi
        
        # Copy data files if they exist
        if [[ -d "$EXTRACTED_DIR/share" ]]; then
            cp -r "$EXTRACTED_DIR/share" "$WORKSHOP_DIR/"
            echo "Copied OCC data files"
        fi
        
        # Clean up extracted directory
        rm -rf "$EXTRACTED_DIR"
    else
        echo "Error: Could not find extracted directory $EXTRACTED_DIR"
        exit 1
    fi

    # Clean up
    rm -f "$ARCHIVE_NAME"

    # Make executable
    chmod +x "$BIN_DIR/occ"
fi

# Check if XTB is already installed
if [[ -f "$BIN_DIR/xtb" ]]; then
    echo "XTB already installed in $BIN_DIR, skipping download..."
else
    # Download XTB
    echo ""
    echo "Downloading XTB..."

    # Get latest XTB release
    XTB_RELEASE=$(curl -s https://api.github.com/repos/grimme-lab/xtb/releases/latest)
    XTB_VERSION=$(echo "$XTB_RELEASE" | grep '"tag_name"' | sed 's/.*"tag_name": *"v\([^"]*\)".*/\1/')

    if [[ -z "$XTB_VERSION" ]]; then
        echo "Warning: Failed to get XTB version, skipping XTB installation"
    else
        echo "XTB version: $XTB_VERSION"
        
        # Construct XTB download URL based on platform
        case "$PLATFORM_SUFFIX" in
            "linux-x86_64")
                XTB_ARCHIVE="xtb-${XTB_VERSION}-linux-x86_64.tar.xz"
                ;;
            "macos-arm64"|"macos-x86_64")
                echo "Warning: XTB doesn't provide macOS binaries. Install via:"
                echo "  brew tap grimme-lab/qc"
                echo "  brew install xtb"
                echo "or:"
                echo "  conda install -c conda-forge xtb"
                XTB_ARCHIVE=""
                ;;
            *)
                echo "Warning: No XTB binary available for $PLATFORM_SUFFIX"
                XTB_ARCHIVE=""
                ;;
        esac
        
        if [[ -n "$XTB_ARCHIVE" ]]; then
            XTB_URL="https://github.com/grimme-lab/xtb/releases/download/v${XTB_VERSION}/${XTB_ARCHIVE}"
            echo "Download URL: $XTB_URL"
            
            # Download and extract XTB
            if curl -L "$XTB_URL" -o "$XTB_ARCHIVE"; then
                echo "Extracting XTB..."
                tar -xf "$XTB_ARCHIVE"
                
                # Find extracted directory and copy executable
                XTB_EXTRACTED_DIR="xtb-${XTB_VERSION}"
                if [[ -d "$XTB_EXTRACTED_DIR" ]]; then
                    if [[ -f "$XTB_EXTRACTED_DIR/bin/xtb" ]]; then
                        cp "$XTB_EXTRACTED_DIR/bin/xtb" "$BIN_DIR/"
                        chmod +x "$BIN_DIR/xtb"
                        echo "✓ XTB installation successful!"
                        
                        # Copy XTB data files if they exist
                        if [[ -d "$XTB_EXTRACTED_DIR/share" ]]; then
                            mkdir -p "$WORKSHOP_DIR/share"
                            cp -r "$XTB_EXTRACTED_DIR/share"/* "$WORKSHOP_DIR/share/" 2>/dev/null || true
                        fi
                    else
                        echo "Warning: XTB executable not found in expected location"
                        # Try to find it in different locations
                        XTB_PATH=$(find "$XTB_EXTRACTED_DIR" -name "xtb" -type f 2>/dev/null | head -1)
                        if [[ -n "$XTB_PATH" ]]; then
                            cp "$XTB_PATH" "$BIN_DIR/"
                            chmod +x "$BIN_DIR/xtb"
                            echo "✓ Found and installed XTB from: $XTB_PATH"
                        else
                            echo "Warning: Could not find XTB executable anywhere in archive"
                        fi
                    fi
                    rm -rf "$XTB_EXTRACTED_DIR"
                else
                    echo "Warning: XTB extraction failed - checking archive contents..."
                    tar -tf "$XTB_ARCHIVE" | head -10
                fi
                rm -f "$XTB_ARCHIVE"
            else
                echo "Warning: Failed to download XTB from $XTB_URL"
            fi
        fi
    fi
fi

# Create environment setup script
cat > "$WORKSHOP_DIR/setup_env.sh" << 'EOF'
#!/bin/bash
# Source this file to set up the workshop environment
# Usage: source setup_env.sh

WORKSHOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$WORKSHOP_DIR/bin:$PATH"

# Set OCC data path if share directory exists
if [[ -d "$WORKSHOP_DIR/share/occ" ]]; then
    export OCC_DATA_PATH="$WORKSHOP_DIR/share/occ"
fi

echo "Workshop environment set up:"
echo "  OCC binary: $(which occ 2>/dev/null || echo 'NOT FOUND')"
echo "  OCC data path: ${OCC_DATA_PATH:-'NOT SET'}"
EOF

# Test installations
echo ""
echo "Testing installations..."
export PATH="$BIN_DIR:$PATH"
if [[ -d "$WORKSHOP_DIR/share/occ" ]]; then
    export OCC_DATA_PATH="$WORKSHOP_DIR/share/occ"
fi

# Test OCC
if "$BIN_DIR/occ" --help > /dev/null 2>&1; then
    echo "✓ OCC installation successful!"
else
    echo "✗ OCC installation failed!"
    echo "Check that the binary is working:"
    echo "  $BIN_DIR/occ --help"
    exit 1
fi

# Test XTB if installed
if [[ -f "$BIN_DIR/xtb" ]]; then
    if "$BIN_DIR/xtb" --help > /dev/null 2>&1; then
        echo "✓ XTB installation successful!"
    else
        echo "⚠ XTB installed but not working properly"
    fi
fi

echo ""
echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Run: source setup_env.sh"
echo "2. Test: ./scripts/test_installation.sh"
echo "3. Start workshop: see geometries/ directory"