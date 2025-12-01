#!/bin/bash
# Fix LaTeX CSLReferences formatting issue on macOS

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <latex_file>" >&2
    exit 1
fi

LATEX_FILE="$1"

if [ ! -f "$LATEX_FILE" ]; then
    echo "Error: LaTeX file not found: $LATEX_FILE" >&2
    exit 1
fi

# Fix the CSLReferences formatting issue
sed -i.bak 's/}\\% \\AtEndEnvironment{CSLReferences}/}\n\\AtEndEnvironment{CSLReferences}/' "$LATEX_FILE"
rm -f "${LATEX_FILE}.bak"

