#!/bin/bash
# Fix LaTeX CSLReferences formatting issue and CJK bold font configuration on Linux

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

# Fix CJK bold font configuration
# Extract CJK font name from \setCJKmainfont{...} and add \setCJKboldfont in preamble
python3 <<PYTHON_EOF
import re
import sys

file_path = '$LATEX_FILE'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find \setCJKmainfont{...} and extract font name (search anywhere in document)
cjk_font_pattern = r'\\setCJKmainfont\{([^}]+)\}'
match = re.search(cjk_font_pattern, content)

if match:
    cjk_font = match.group(1)
    # Find \begin{document} to locate preamble
    doc_begin_pos = content.find(r'\begin{document}')
    if doc_begin_pos > 0:
        preamble = content[:doc_begin_pos]
        document_body = content[doc_begin_pos:]
        
        # Check if xeCJK is already in preamble
        needs_xecjk = r'\usepackage{xeCJK}' not in preamble
        needs_mainfont = r'\setCJKmainfont' not in preamble
        needs_boldfont = r'\setCJKboldfont' not in content
        
        if needs_xecjk or needs_mainfont or needs_boldfont:
            # Build commands to add
            commands_to_add = []
            if needs_xecjk:
                commands_to_add.append(r'\usepackage{xeCJK}')
            if needs_mainfont:
                commands_to_add.append(r'\setCJKmainfont{' + cjk_font + '}')
            if needs_boldfont:
                commands_to_add.append(r'\setCJKboldfont{' + cjk_font + '}')
            
            # Add commands before \begin{document}
            if commands_to_add:
                content = preamble + '\n'.join(commands_to_add) + '\n' + document_body
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
PYTHON_EOF

rm -f "${LATEX_FILE}.bak"

