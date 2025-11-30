#!/bin/bash
# Clean build artifacts on macOS

set -e

PDF="${1:-paper.pdf}"
COVER_PDF="${2:-cover.pdf}"
PRINTED_PDF="${3:-printed.pdf}"
TEMP_SRC="${4:-paper.tmp.md}"
COVER_TEMP_TEX="${5:-ntust_cover_page.tmp.tex}"

rm -f "$PDF"
rm -f "$COVER_PDF" "$PRINTED_PDF"
rm -f "$TEMP_SRC" "$COVER_TEMP_TEX"
rm -f *.aux *.log *.out *.toc *.bbl *.blg *.bcf *.run.xml *.synctex.gz
rm -f *.fdb_latexmk *.fls *.xdv *.nav *.snm *.vrb *.lof *.lot *.loa *.lol
rm -rf _minted*

echo "Cleaned build outputs and LaTeX intermediates."

