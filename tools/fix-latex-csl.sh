#!/bin/bash
# Fix LaTeX CSLReferences formatting issue on Linux

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

# Make reference items a numbered list (1. 2. 3. ...)
sed -i.bak 's/\\begin{list}{}{%/\\begin{list}{\\arabic{enumi}.}{\\usecounter{enumi}\\setlength{\\labelwidth}{2em}%/g' "$LATEX_FILE"
# Disable hanging indent; set proper left margin for number labels
sed -i.bak 's/\\begin{CSLReferences}{1}/\\begin{CSLReferences}{0}/g' "$LATEX_FILE"
sed -i.bak 's/\\setlength{\\leftmargin}{0pt}/\\setlength{\\leftmargin}{2.5em}/g' "$LATEX_FILE"
# Replace \bibitem with \item + \hypertarget to get numbered entries without extra blank lines
sed -i.bak '/\\begin{CSLReferences}/,/\\end{CSLReferences}/ s/\\bibitem\[\\citeproctext\]{\([^}]*\)}/\\item \\hypertarget{\1}{}/g' "$LATEX_FILE"

# Fix \citeproc command to output pre-formatted text with hyperlink instead of calling \cite
# The \citeproc command gets two arguments: #1 = cite key (e.g., ref-foo), #2 = formatted text (e.g., "Author 2020")
# Since Pandoc has already formatted the citation, we just need to output #2 with a hyperlink to #1
sed -i.bak 's/\\NewDocumentCommand\\citeproc{mm}{%/\\NewDocumentCommand\\citeproc{mm}{%/' "$LATEX_FILE"
sed -i.bak '/\\NewDocumentCommand\\citeproc{mm}{%/,/\\endgroup}/ {
  s/\\begingroup\\def\\citeproctext{#2}\\cite{#1}\\endgroup/\\hyperlink{#1}{#2}/
}' "$LATEX_FILE"

rm -f "${LATEX_FILE}.bak"

