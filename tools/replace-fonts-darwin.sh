#!/bin/bash
# Replace font names in markdown/LaTeX files on macOS

set -e

if [ $# -lt 3 ]; then
    echo "Usage: $0 <input_file> <output_file> <old_font> <new_font> [old_font2] [new_font2] ..." >&2
    echo "Example: $0 input.md output.md 'PingFang SC' 'AR PL UMing CN'" >&2
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"
shift 2

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE" >&2
    exit 1
fi

# Build sed command with all font replacements
SED_CMD=""
while [ $# -ge 2 ]; do
    OLD_FONT="$1"
    NEW_FONT="$2"
    shift 2
    # Escape special characters for sed
    OLD_FONT_ESC=$(echo "$OLD_FONT" | sed 's/[[\.*^$()+?{|]/\\&/g')
    SED_CMD="${SED_CMD} -e 's/${OLD_FONT_ESC}/${NEW_FONT}/g'"
done

# Apply replacements
eval "sed ${SED_CMD} '$INPUT_FILE' > '$OUTPUT_FILE'"

