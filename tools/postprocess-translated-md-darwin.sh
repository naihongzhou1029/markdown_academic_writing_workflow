#!/bin/bash
# Post-process translated markdown file on macOS

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
import re

file_path = '$TRANSLATED_MD'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

lines = content.split('\n')
in_block = False
result = []

for i, line in enumerate(lines):
    # Start of multi-line YAML block
    if line.rstrip() == '- |':
        in_block = True
        result.append(line)
    # End of block: next top-level YAML key (starts with letter, ends with colon, no leading spaces)
    elif in_block and re.match(r'^[a-zA-Z].*:$', line.rstrip()):
        in_block = False
        result.append(line)
    # Inside block: fix indentation for LaTeX commands
    elif in_block:
        # Already properly indented (4+ spaces)
        if line.startswith('    '):
            result.append(line)
        # LaTeX command that needs indentation
        elif len(line) > 0 and line[0] == chr(92) and not line.startswith(' '):
            result.append('    ' + line)
        # Empty line - preserve as is
        elif not line.strip():
            result.append(line)
        # Other content in block - indent if not already indented
        else:
            result.append('    ' + line if not line.startswith(' ') else line)
    else:
        result.append(line)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(result))
PYTHON_EOF

