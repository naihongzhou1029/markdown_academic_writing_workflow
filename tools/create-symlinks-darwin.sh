#!/bin/bash
# Create symbolic links for dependencies in target directory on macOS

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <target_dir> <file1> [file2] [file3] ..." >&2
    exit 1
fi

TARGET_DIR="$1"
shift

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory not found: $TARGET_DIR" >&2
    exit 1
fi

# Create symlinks for each file
for FILE in "$@"; do
    if [ ! -f "$FILE" ]; then
        echo "Warning: Source file not found: $FILE, skipping..." >&2
        continue
    fi
    
    BASENAME=$(basename "$FILE")
    TARGET_PATH="$TARGET_DIR/$BASENAME"
    
    # Remove existing file/link if it exists
    if [ -e "$TARGET_PATH" ]; then
        rm -f "$TARGET_PATH"
    fi
    
    # Create symlink (relative path)
    cd "$TARGET_DIR"
    ln -sf "../$FILE" "$BASENAME"
    cd - > /dev/null
done

