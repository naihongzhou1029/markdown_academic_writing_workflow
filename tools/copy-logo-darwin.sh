#!/bin/bash
# Copy or create symlink for logo file in target directory on macOS

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <source_logo> <target_dir>" >&2
    exit 1
fi

SOURCE_LOGO="$1"
TARGET_DIR="$2"

if [ ! -f "$SOURCE_LOGO" ]; then
    echo "Error: Source logo file not found: $SOURCE_LOGO" >&2
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory not found: $TARGET_DIR" >&2
    exit 1
fi

BASENAME=$(basename "$SOURCE_LOGO")
TARGET_PATH="$TARGET_DIR/$BASENAME"

# Remove existing file/link if it exists
if [ -e "$TARGET_PATH" ]; then
    rm -f "$TARGET_PATH"
fi

# Try to create symlink first, fallback to copy
cd "$TARGET_DIR"
if ln -sf "../$SOURCE_LOGO" "$BASENAME" 2>/dev/null; then
    # Symlink created successfully
    :
else
    # Fallback to copy
    cp "../$SOURCE_LOGO" "$BASENAME" 2>/dev/null || true
fi
cd - > /dev/null

