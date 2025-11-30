#!/bin/bash
# Install dependencies on macOS using Homebrew

set -e

echo "Installing required CLI tools with Homebrew (if missing)..."

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Install it from https://brew.sh and re-run this script." >&2
    exit 1
fi

brew list --formula poppler >/dev/null 2>&1 || brew install poppler
brew list --formula ghostscript >/dev/null 2>&1 || brew install ghostscript
brew list --formula pandoc-crossref >/dev/null 2>&1 || brew install pandoc-crossref

echo "All dependencies are installed."

