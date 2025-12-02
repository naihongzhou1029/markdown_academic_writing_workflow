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
# Core document conversion tool
dpkg -l | grep -q "^ii.*pandoc" || sudo apt-get install -y pandoc
dpkg -l | grep -q "^ii\s\+fonts-noto-cjk\s" || sudo apt-get install -y fonts-noto-cjk
dpkg -l | grep -q "^ii\s\+fonts-liberation\s" || sudo apt-get install -y fonts-liberation

# jq is used by translation scripts; install it if the CLI is missing
if ! command -v jq >/dev/null 2>&1; then
    sudo apt-get install -y jq
fi

# Ensure ~/.cabal/bin and ~/.local/bin are in PATH for this script
export PATH="$HOME/.cabal/bin:$HOME/.local/bin:$PATH"

if ! command -v pandoc-crossref >/dev/null 2>&1; then
    # Only install pandoc-crossref if it's not already available in the system.
    # We do NOT try to force version alignment with pandoc to avoid long rebuilds
    # and to respect an existing system-wide installation.
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

echo "All dependencies are installed."

