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
dpkg -l | grep -q "^ii.*fonts-noto-cjk" || sudo apt-get install -y fonts-noto-cjk
dpkg -l | grep -q "^ii.*fonts-liberation" || sudo apt-get install -y fonts-liberation

if ! command -v pandoc-crossref >/dev/null 2>&1; then
    if command -v cabal >/dev/null 2>&1; then
        echo "Installing pandoc-crossref via cabal..."
        cabal update && cabal install pandoc-crossref
    else
        echo "pandoc-crossref not found. Install it via:" >&2
        echo "  sudo apt-get install -y cabal-install" >&2
        echo "  cabal update && cabal install pandoc-crossref" >&2
        echo "Or download a binary release from: https://github.com/lierdakil/pandoc-crossref/releases" >&2
        exit 1
    fi
else
    PANDOC_VER=$(pandoc --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    CROSSREF_VER=$(pandoc-crossref --version 2>&1 | grep -oE 'Pandoc v[0-9]+\.[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    if [ -n "$PANDOC_VER" ] && [ -n "$CROSSREF_VER" ] && [ "$PANDOC_VER" != "$CROSSREF_VER" ]; then
        echo "Warning: pandoc-crossref (built with pandoc $CROSSREF_VER) doesn't match installed pandoc ($PANDOC_VER)"
        echo "Reinstalling pandoc-crossref to match pandoc version..."
        if command -v cabal >/dev/null 2>&1; then
            cabal update && cabal install pandoc-crossref
        else
            echo "cabal not found. Please install cabal-install and reinstall pandoc-crossref:" >&2
            echo "  sudo apt-get install -y cabal-install" >&2
            echo "  cabal update && cabal install pandoc-crossref" >&2
            exit 1
        fi
    fi
fi

echo "All dependencies are installed."

