#!/bin/bash
# Merge one or more PDFs on Linux using pdfunite or Ghostscript.
#
# Usage:
#   merge-pdfs.sh input1.pdf input2.pdf [input3.pdf ...] output.pdf
# The last argument is treated as the output file; all preceding arguments
# are merged in the order provided.

set -e

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <input1.pdf> <input2.pdf> [input3.pdf ...] <output.pdf>" >&2
    exit 1
fi

# Last argument is output; all others are inputs.
OUTPUT="${@: -1}"
INPUTS=("${@:1:$(($#-1))}")

if command -v pdfunite >/dev/null 2>&1; then
    pdfunite "${INPUTS[@]}" "$OUTPUT"
    echo "Created $OUTPUT from ${#INPUTS[@]} input PDF(s) with pdfunite."
elif command -v gs >/dev/null 2>&1; then
    gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="$OUTPUT" "${INPUTS[@]}"
    echo "Created $OUTPUT from ${#INPUTS[@]} input PDF(s) with Ghostscript (gs)."
else
    echo "Neither pdfunite nor gs found. Install poppler-utils (pdfunite) with 'sudo apt-get install poppler-utils'" >&2
    echo "or Ghostscript with 'sudo apt-get install ghostscript' to enable PDF merging." >&2
    exit 1
fi

#
