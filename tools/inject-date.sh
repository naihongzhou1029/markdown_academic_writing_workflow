#!/bin/bash
# Inject current date into LaTeX cover page template

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <tex_file>" >&2
    exit 1
fi

TEX_FILE="$1"

if [ ! -f "$TEX_FILE" ]; then
    echo "Error: File not found: $TEX_FILE" >&2
    exit 1
fi

# Replace the ROCDate with current date
CURRENT_DATE=$(date +"%B %d, %Y")
sed -i.bak "s|\\\\newcommand{\\\\ROCDate}{.*}|\\\\newcommand{\\\\ROCDate}{${CURRENT_DATE}}|" "$TEX_FILE"
rm -f "${TEX_FILE}.bak"

