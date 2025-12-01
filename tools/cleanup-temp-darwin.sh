#!/bin/bash
# Remove temporary files created during build process on macOS

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <file1> [file2] [file3] ..." >&2
    exit 1
fi

# Remove each file
for FILE in "$@"; do
    if [ -f "$FILE" ] || [ -d "$FILE" ]; then
        rm -rf "$FILE"
    fi
done

