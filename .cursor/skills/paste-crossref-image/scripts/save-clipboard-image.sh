#!/usr/bin/env bash
# Saves macOS clipboard image to images/YYYY-MM-DD-HH-MM-SS.png
# Uses AppleScript to preserve color fidelity (pngpaste has known washed-out color issues)

IMGDIR="${1:-images}"
[[ "$IMGDIR" != /* ]] && IMGDIR="$(pwd)/$IMGDIR"
IMGDIR="$(cd "$(dirname "$IMGDIR")" 2>/dev/null && pwd)/$(basename "$IMGDIR")"
mkdir -p "$IMGDIR"
FILENAME=$(date +%Y-%m-%d-%H-%M-%S).png
FILEPATH="$IMGDIR/$FILENAME"

# Remove existing file so osascript can create it
rm -f "$FILEPATH"

if osascript -e "tell application \"System Events\" to write (the clipboard as «class PNGf») to (make new file at folder \"$IMGDIR\" with properties {name:\"$FILENAME\"})" 2>/dev/null; then
  if [[ -f "$FILEPATH" ]]; then
    echo "$FILEPATH"
  else
    echo "ERROR: Clipboard does not contain an image, or AppleScript failed." >&2
    exit 1
  fi
else
  echo "ERROR: Clipboard does not contain an image, or AppleScript failed." >&2
  exit 1
fi
