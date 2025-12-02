#!/bin/bash
# Post-process translated markdown file on Linux

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <translated_md_file> <cjk_font>" >&2
    exit 1
fi

TRANSLATED_MD="$1"
CJK_FONT="$2"

if [ ! -f "$TRANSLATED_MD" ]; then
    echo "Error: Translated markdown file not found: $TRANSLATED_MD" >&2
    exit 1
fi

# Apply sed replacements
sed -i.bak \
    -e "s/CJKmainfont: \"PingFang SC\"/CJKmainfont: \"${CJK_FONT}\"/" \
    -e "s/setCJKmainfont{PingFang SC}/setCJKmainfont{${CJK_FONT}}/" \
    -e 's/"Figure"/"圖"/' \
    -e 's/"Figures"/"圖"/' \
    -e 's/"Tab\."/"表"/' \
    "$TRANSLATED_MD"
rm -f "${TRANSLATED_MD}.bak"

# Apply Python-based indentation fixes
python3 <<PYTHON_EOF
import sys

file_path = '$TRANSLATED_MD'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

lines = content.split('\n')
in_block = False
result = []

for line in lines:
    if line.rstrip() == '- |':
        in_block = True
        result.append(line)
    elif in_block and line.startswith(r'\usepackage{etoolbox}'):
        result.append('    ' + line)
    elif in_block and line.startswith(r'\AtBeginEnvironment{CSLReferences}'):
        result.append('    ' + line)
    elif in_block and line.startswith(r'\newpage\section*{References}'):
        result.append('      ' + line)
    elif in_block and line.startswith(r'\setlength{'):
        result.append('      ' + line)
    elif in_block and line.rstrip() == '}':
        result.append('    ' + line)
        in_block = False
    else:
        result.append(line)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(result))
PYTHON_EOF

