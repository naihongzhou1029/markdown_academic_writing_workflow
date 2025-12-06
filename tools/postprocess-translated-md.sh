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

# Apply Python-based fixes for YAML structure and indentation
export TRANSLATED_MD_FILE="$TRANSLATED_MD"
python3 <<'PYTHON_EOF'
import sys
import os
import re

file_path = os.environ['TRANSLATED_MD_FILE']

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

lines = content.split('\n')
in_block = False
result = []
i = 0

while i < len(lines):
    line = lines[i]
    
    # Fix abstract: | or abstract: |- with unindented content
    if re.match(r'^abstract:\s+\|', line.rstrip()):
        # Check if next line is content and line after that is a new YAML key
        if i + 1 < len(lines):
            content_line = lines[i + 1]
            # If next line is content (not empty, not a YAML key, not indented)
            if content_line.strip() and not re.match(r'^[a-zA-Z].*:$', content_line.rstrip()) and not content_line.startswith(' '):
                # Check if line after content is a YAML key or end of YAML block
                if i + 2 < len(lines):
                    next_line = lines[i + 2]
                    if re.match(r'^[a-zA-Z].*:$', next_line.rstrip()) or next_line.rstrip() == '---':
                        # Convert to quoted string format
                        # Properly escape for YAML: backslashes first, then quotes
                        escaped_content = content_line.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
                        result.append(f'abstract: "{escaped_content}"')
                        i += 2  # Skip the | line and content line
                        continue
                elif i + 2 == len(lines):
                    # Last line case - treat as single line abstract
                    escaped_content = content_line.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
                    result.append(f'abstract: "{escaped_content}"')
                    i += 2
                    continue
        # If we get here, we have abstract: | with multiline - ensure content is indented
        result.append(line)
        i += 1
        # Indent the next line if it's not already indented
        if i < len(lines):
            content_line = lines[i]
            if content_line.strip() and not content_line.startswith(' '):
                result.append('  ' + content_line)
                i += 1
        continue
    
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
    
    i += 1

with open(file_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(result))
PYTHON_EOF

