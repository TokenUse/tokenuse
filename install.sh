#!/bin/bash
set -euo pipefail

# TokenUse CLI Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/tokenuse/tokenuse/main/install.sh | bash

GITHUB_REPO="tokenuse/tokenuse"
DOWNLOAD_BASE="https://github.com/$GITHUB_REPO/releases"
VERSION="${TOKENUSE_VERSION:-latest}"

# Second trust domain (W1-REL-3 / CISO-02): a mirror of the checksum manifest and
# the minisign public key, served from a different repo/origin than the release
# assets (raw.githubusercontent.com vs the release download host). The installer
# cross-checks the primary checksums against this copy so an attacker who can swap
# release assets cannot also forge the verifying anchor. Override for testing.
MIRROR_BASE="${TOKENUSE_MIRROR_BASE:-https://raw.githubusercontent.com/tokenuse/tokenuse-releases/main}"

# Committed minisign (Ed25519) public key used to verify SHA256SUMS.minisig.
# CARRIED: until the real release-signing key is published, this is a placeholder.
# While it equals the placeholder the installer cannot verify signatures and will
# WARN-and-skip (verify-when-available). Once a real key is set here, a present-but-
# invalid signature is FATAL. Replace the value below with the published key line:
#   minisign public key: <KEYID>
#   RWQ...base64...
MINISIGN_PUBKEY="REPLACE_WITH_PUBLISHED_KEY"
if [ -n "${TOKENUSE_INSTALL_DIR:-}" ]; then
    INSTALL_DIR="$TOKENUSE_INSTALL_DIR"
else
    if [ -z "${HOME:-}" ]; then
        echo "error: HOME is not set and TOKENUSE_INSTALL_DIR was not provided" >&2
        exit 1
    fi
    INSTALL_DIR="$HOME/.local/bin"
fi

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
    OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
    ARCH="$(uname -m)"

    case "$OS" in
        darwin)
            OS="darwin"
            if { [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; } && [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || true)" = "1" ]; then
                ARCH="arm64"
                info "Rosetta translation detected; selecting darwin_arm64 binary"
            fi
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
        LATEST_JSON="$(curl -fsSL "https://api.github.com/repos/$GITHUB_REPO/releases/latest")"
        VERSION="$(printf '%s\n' "$LATEST_JSON" | sed -nE 's/.*"tag_name": *"v([^"]+)".*/\1/p')"
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
    TMP_DIR=""

    cleanup() {
        if [ -n "${TMP_DIR:-}" ] && [ -d "$TMP_DIR" ]; then
            rm -rf "$TMP_DIR"
        fi
    }

    info "Downloading from $DOWNLOAD_URL"

    # Create temp directory
    TMP_DIR="$(mktemp -d)"
    trap cleanup EXIT

    # Download tarball
    curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/tokenuse.tar.gz"

    # Verify checksum (fail-closed: any failure aborts the install, mirroring the
    # npm installer). Escape hatch for offline/dev only: set TOKENUSE_SKIP_CHECKSUM=1
    # to bypass (default off).
    if [ "${TOKENUSE_SKIP_CHECKSUM:-}" = "1" ]; then
        warn "TOKENUSE_SKIP_CHECKSUM=1 set, skipping checksum verification (insecure)"
    else
        info "Verifying checksum..."

        # A missing/unreachable checksums file must abort — never install unverified.
        if ! curl -fsSL "$CHECKSUM_URL" -o "$TMP_DIR/checksums.txt"; then
            error "Could not download checksums for v$VERSION from $CHECKSUM_URL.\nRefusing to install an unverified binary. Set TOKENUSE_SKIP_CHECKSUM=1 to override (insecure)."
        fi

        CHECKSUM_FILENAME="tokenuse_${VERSION}_${PLATFORM}.tar.gz"
        EXPECTED_CHECKSUM="$(awk -v filename="$CHECKSUM_FILENAME" '$2 == filename { print $1 }' "$TMP_DIR/checksums.txt")"
        if [ -z "$EXPECTED_CHECKSUM" ]; then
            error "No checksum entry for $CHECKSUM_FILENAME in checksums.txt.\nRefusing to install an unverified binary. Set TOKENUSE_SKIP_CHECKSUM=1 to override (insecure)."
        fi

        if command -v sha256sum >/dev/null 2>&1; then
            ACTUAL_CHECKSUM="$(sha256sum "$TMP_DIR/tokenuse.tar.gz" | awk '{print $1}')"
        elif command -v shasum >/dev/null 2>&1; then
            ACTUAL_CHECKSUM="$(shasum -a 256 "$TMP_DIR/tokenuse.tar.gz" | awk '{print $1}')"
        else
            error "No sha256 tool (sha256sum/shasum) available to verify the download.\nRefusing to install an unverified binary. Set TOKENUSE_SKIP_CHECKSUM=1 to override (insecure)."
        fi

        if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
            error "Checksum verification failed!\nExpected: $EXPECTED_CHECKSUM\nActual: $ACTUAL_CHECKSUM"
        fi
        info "Checksum verified"

        # --- Cross-domain checksum verification (W1-REL-3 / CISO-02) ---
        # Fetch SHA256SUMS from the second trust domain and compare byte-for-byte
        # against the primary release copy. A divergence means the two independent
        # publish paths disagree -> treat as tamper and abort. Skip-with-warning
        # only when the mirror is unreachable AND no real signing key is configured
        # (the mirror is not yet populated before go-live).
        MIRROR_URL="$MIRROR_BASE/v$VERSION/SHA256SUMS"
        if curl -fsSL "$MIRROR_URL" -o "$TMP_DIR/checksums.mirror.txt" 2>/dev/null; then
            if cmp -s "$TMP_DIR/checksums.txt" "$TMP_DIR/checksums.mirror.txt"; then
                info "Second-domain checksums match ($MIRROR_BASE)"
            else
                error "Checksums on the second trust domain do not match the release copy.\nPrimary: $CHECKSUM_URL\nMirror:  $MIRROR_URL\nRefusing to install a possibly tampered binary."
            fi
        elif [ "$MINISIGN_PUBKEY" != "REPLACE_WITH_PUBLISHED_KEY" ]; then
            error "Could not fetch second-domain checksums from $MIRROR_URL while a signing key is configured.\nRefusing to install without the out-of-band anchor. Set TOKENUSE_SKIP_CHECKSUM=1 to override (insecure)."
        else
            warn "Second-domain checksum mirror unreachable ($MIRROR_URL); skipping cross-check (no signing key configured yet)."
        fi

        # --- minisign signature verification (W1-REL-3 / CISO-02) ---
        # Verify SHA256SUMS.minisig against the committed public key. Verify-when-
        # available: if minisign is missing or no signature is published, warn and
        # continue (checksum + cross-domain check still applied). But once a real
        # public key is set here AND a signature is present, a verification failure
        # is FATAL (fail-closed on tamper).
        SIG_URL="$DOWNLOAD_BASE/download/v$VERSION/SHA256SUMS.minisig"
        if [ "$MINISIGN_PUBKEY" = "REPLACE_WITH_PUBLISHED_KEY" ]; then
            warn "minisign public key not yet published in installer; skipping signature verification (verify-when-available)."
        elif ! command -v minisign >/dev/null 2>&1; then
            warn "minisign not installed; skipping signature verification. Install minisign to verify the release signature (recommended)."
        elif ! curl -fsSL "$SIG_URL" -o "$TMP_DIR/SHA256SUMS.minisig" 2>/dev/null; then
            error "Signing key is configured but no signature ($SIG_URL) was found for v$VERSION.\nRefusing to install an unsigned binary. Set TOKENUSE_SKIP_CHECKSUM=1 to override (insecure)."
        else
            info "Verifying minisign signature..."
            if minisign -V -P "$MINISIGN_PUBKEY" \
                -m "$TMP_DIR/checksums.txt" \
                -x "$TMP_DIR/SHA256SUMS.minisig" >/dev/null 2>&1; then
                info "Signature verified"
            else
                error "minisign signature verification failed for SHA256SUMS.\nRefusing to install a possibly tampered binary."
            fi
        fi
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
    if [[ ":${PATH:-}:" != *":$INSTALL_DIR:"* ]]; then
        warn "$INSTALL_DIR is not in your PATH"

        if [ -n "${SHELL:-}" ]; then
            SHELL_NAME="$(basename "$SHELL")"
        else
            SHELL_NAME=""
        fi
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
    echo "  Privacy: TokenUse collects usage metadata and, by default, prompts. https://www.tokenuse.ai/trust"
    echo ""
}

main "$@"
