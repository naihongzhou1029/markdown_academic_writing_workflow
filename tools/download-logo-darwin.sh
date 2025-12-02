#!/bin/bash
# Download NTUST logo on macOS

set -e

LOGO_FILE="$1"
LOGO_URL="$2"

if [ -z "$LOGO_FILE" ] || [ -z "$LOGO_URL" ]; then
    echo "Usage: $0 <logo_file> <logo_url>" >&2
    exit 1
fi

echo "Fetching NTUST logo..."
curl -fsSL -o "$LOGO_FILE" "$LOGO_URL"

