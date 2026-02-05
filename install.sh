#!/bin/bash
set -e

# TokenUse CLI Installer
# Usage: curl -fsSL https://get.tokenuse.ai | bash

VERSION="${TOKENUSE_VERSION:-latest}"
INSTALL_DIR="${TOKENUSE_INSTALL_DIR:-$HOME/.local/bin}"
GITHUB_REPO="tokenuse/tokenuse"
DOWNLOAD_BASE="https://github.com/$GITHUB_REPO/releases"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}info${NC}: $1"
}

warn() {
    echo -e "${YELLOW}warn${NC}: $1"
}

error() {
    echo -e "${RED}error${NC}: $1" >&2
    exit 1
}

# Detect OS and architecture
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "$OS" in
        darwin)
            OS="darwin"
            ;;
        linux)
            OS="linux"
            ;;
        *)
            error "Unsupported operating system: $OS"
            ;;
    esac

    case "$ARCH" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            ;;
        *)
            error "Unsupported architecture: $ARCH"
            ;;
    esac

    PLATFORM="${OS}_${ARCH}"
    info "Detected platform: $PLATFORM"
}

# Get the latest version from GitHub
get_latest_version() {
    if [ "$VERSION" = "latest" ]; then
        VERSION=$(curl -fsSL "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
        if [ -z "$VERSION" ]; then
            error "Failed to fetch latest version"
        fi
    fi
    info "Version: $VERSION"
}

# Download and verify binary
download_binary() {
    DOWNLOAD_URL="$DOWNLOAD_BASE/download/v$VERSION/tokenuse_${VERSION}_${PLATFORM}.tar.gz"
    CHECKSUM_URL="$DOWNLOAD_BASE/download/v$VERSION/checksums.txt"

    info "Downloading from $DOWNLOAD_URL"

    # Create temp directory
    TMP_DIR=$(mktemp -d)
    trap "rm -rf $TMP_DIR" EXIT

    # Download tarball
    curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/tokenuse.tar.gz"

    # Download checksums
    curl -fsSL "$CHECKSUM_URL" -o "$TMP_DIR/checksums.txt"

    # Verify checksum
    info "Verifying checksum..."
    EXPECTED_CHECKSUM=$(grep "tokenuse_${VERSION}_${PLATFORM}.tar.gz" "$TMP_DIR/checksums.txt" | awk '{print $1}')

    if [ -z "$EXPECTED_CHECKSUM" ]; then
        warn "Checksum not found, skipping verification"
    else
        if command -v sha256sum &> /dev/null; then
            ACTUAL_CHECKSUM=$(sha256sum "$TMP_DIR/tokenuse.tar.gz" | awk '{print $1}')
        elif command -v shasum &> /dev/null; then
            ACTUAL_CHECKSUM=$(shasum -a 256 "$TMP_DIR/tokenuse.tar.gz" | awk '{print $1}')
        else
            warn "sha256sum not found, skipping verification"
            ACTUAL_CHECKSUM=""
        fi

        if [ -n "$ACTUAL_CHECKSUM" ] && [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
            error "Checksum verification failed!\nExpected: $EXPECTED_CHECKSUM\nActual: $ACTUAL_CHECKSUM"
        fi
        info "Checksum verified"
    fi

    # Extract
    info "Extracting..."
    tar -xzf "$TMP_DIR/tokenuse.tar.gz" -C "$TMP_DIR"

    # Install (binary is in tokenuse_VERSION_PLATFORM directory)
    mkdir -p "$INSTALL_DIR"
    mv "$TMP_DIR/tokenuse_${VERSION}_${PLATFORM}/tokenuse" "$INSTALL_DIR/tokenuse"
    chmod +x "$INSTALL_DIR/tokenuse"

    info "Installed to $INSTALL_DIR/tokenuse"
}

# Add to PATH if needed
setup_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        warn "$INSTALL_DIR is not in your PATH"

        SHELL_NAME=$(basename "$SHELL")
        case "$SHELL_NAME" in
            bash)
                RC_FILE="$HOME/.bashrc"
                ;;
            zsh)
                RC_FILE="$HOME/.zshrc"
                ;;
            fish)
                RC_FILE="$HOME/.config/fish/config.fish"
                ;;
            *)
                RC_FILE=""
                ;;
        esac

        if [ -n "$RC_FILE" ]; then
            echo ""
            echo "Add this to your $RC_FILE:"
            if [ "$SHELL_NAME" = "fish" ]; then
                echo "  set -gx PATH $INSTALL_DIR \$PATH"
            else
                echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
            fi
            echo ""
            echo "Then run: source $RC_FILE"
        fi
    fi
}

# Main
main() {
    echo ""
    echo "  ╔═══════════════════════════════════╗"
    echo "  ║      TokenUse CLI Installer       ║"
    echo "  ╚═══════════════════════════════════╝"
    echo ""

    detect_platform
    get_latest_version
    download_binary
    setup_path

    echo ""
    info "Installation complete!"
    echo ""
    echo "  Get started:"
    echo "    tokenuse          # Sign in and start tracking"
    echo "    tokenuse status   # Check tracking status"
    echo ""
    echo "  View your dashboard at https://app.tokenuse.ai"
    echo ""
}

main "$@"
