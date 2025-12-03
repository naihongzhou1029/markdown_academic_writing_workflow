#!/bin/bash
# Install dependencies on Linux using apt-get

set -e

echo "Installing required CLI tools with apt (if missing)..."

if ! command -v apt-get >/dev/null 2>&1; then
    echo "apt-get not found. This script is for Ubuntu/Debian systems." >&2
    exit 1
fi

sudo apt-get update
dpkg -l | grep -q "^ii.*poppler-utils" || sudo apt-get install -y poppler-utils
dpkg -l | grep -q "^ii.*ghostscript" || sudo apt-get install -y ghostscript
# Core document conversion tool (Pandoc)
dpkg -l | grep -q "^ii.*pandoc" || sudo apt-get install -y pandoc
dpkg -l | grep -q "^ii\s\+fonts-noto-cjk\s" || sudo apt-get install -y fonts-noto-cjk
dpkg -l | grep -q "^ii\s\+fonts-liberation\s" || sudo apt-get install -y fonts-liberation

# jq is used by translation scripts; install it if the CLI is missing
if ! command -v jq >/dev/null 2>&1; then
    sudo apt-get install -y jq
fi

# Align Pandoc version with pandoc-crossref expectations for this repo.
# We rely on pandoc-crossref for stable cross-references AND for a
# reproducible layout of the Table of Contents, List of Figures, and
# List of Tables. To avoid subtle breakage when Pandoc's API changes,
# we pin Pandoc to a known-good version here.
REQUIRED_PANDOC_VER="3.1.8"

if command -v pandoc >/dev/null 2>&1; then
    CURRENT_PANDOC_VER="$(pandoc --version 2>/dev/null | head -n1 | awk '{print $2}')"
else
    CURRENT_PANDOC_VER=""
fi

if [ "$CURRENT_PANDOC_VER" != "$REQUIRED_PANDOC_VER" ]; then
    echo "Upgrading pandoc to version ${REQUIRED_PANDOC_VER} for this workflow..."
    ARCH="$(dpkg --print-architecture)"
    DEB_URL=""

    case "$ARCH" in
        amd64)
            DEB_URL="https://github.com/jgm/pandoc/releases/download/${REQUIRED_PANDOC_VER}/pandoc-${REQUIRED_PANDOC_VER}-1-amd64.deb"
            ;;
        arm64|aarch64)
            DEB_URL="https://github.com/jgm/pandoc/releases/download/${REQUIRED_PANDOC_VER}/pandoc-${REQUIRED_PANDOC_VER}-1-arm64.deb"
            ;;
        *)
            echo "Unsupported architecture '$ARCH' for automatic pandoc ${REQUIRED_PANDOC_VER} install." >&2
            echo "Please install pandoc ${REQUIRED_PANDOC_VER} manually from the official releases." >&2
            DEB_URL=""
            ;;
    esac

    if [ -n "$DEB_URL" ]; then
        TMP_DEB="$(mktemp /tmp/pandoc-${REQUIRED_PANDOC_VER}-XXXXXX.deb)"
        echo "Downloading pandoc from ${DEB_URL}..."
        curl -L "$DEB_URL" -o "$TMP_DEB"
        sudo dpkg -i "$TMP_DEB"
        rm -f "$TMP_DEB"
    fi
fi

# Ensure ~/.cabal/bin and ~/.local/bin are in PATH for this script
export PATH="$HOME/.cabal/bin:$HOME/.local/bin:$PATH"

if ! command -v pandoc-crossref >/dev/null 2>&1; then
    # Install pandoc-crossref only when missing; the binary released for
    # pandoc ${REQUIRED_PANDOC_VER} is expected to work with that pandoc.
    if command -v cabal >/dev/null 2>&1; then
        echo "Installing pandoc-crossref via cabal (not found in PATH)..."
        cabal update && cabal install pandoc-crossref --overwrite-policy=always
        # Refresh PATH after installation
        export PATH="$HOME/.cabal/bin:$HOME/.local/bin:$PATH"
    else
        echo "pandoc-crossref not found in PATH. Install it via:" >&2
        echo "  sudo apt-get install -y cabal-install" >&2
        echo "  cabal update && cabal install pandoc-crossref --overwrite-policy=always" >&2
        echo "Or install your distro package / download a binary from: https://github.com/lierdakil/pandoc-crossref/releases" >&2
        exit 1
    fi
fi

echo "All dependencies (including pinned pandoc ${REQUIRED_PANDOC_VER}) are installed."

