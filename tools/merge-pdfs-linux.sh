#!/bin/bash
# Merge PDFs on Linux using pdfunite or Ghostscript

set -e

COVER_PDF="$1"
PDF="$2"
OUTPUT="$3"

if [ -z "$COVER_PDF" ] || [ -z "$PDF" ] || [ -z "$OUTPUT" ]; then
    echo "Usage: $0 <cover.pdf> <paper.pdf> <output.pdf>" >&2
    exit 1
fi

if command -v pdfunite >/dev/null 2>&1; then
    pdfunite "$COVER_PDF" "$PDF" "$OUTPUT"
    echo "Created $OUTPUT (cover + paper) with pdfunite."
elif command -v gs >/dev/null 2>&1; then
    gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="$OUTPUT" "$COVER_PDF" "$PDF"
    echo "Created $OUTPUT (cover + paper) with Ghostscript (gs)."
else
    echo "Neither pdfunite nor gs found. Install poppler-utils (pdfunite) with 'sudo apt-get install poppler-utils'" >&2
    echo "or Ghostscript with 'sudo apt-get install ghostscript' to enable PDF merging." >&2
    exit 1
fi

