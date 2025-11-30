#!/bin/bash
# Post-process translated LaTeX file on Linux

set -e

if [ $# -ne 3 ]; then
    echo "Usage: $0 <latex_file> <old_font> <new_font>" >&2
    exit 1
fi

LATEX_FILE="$1"
OLD_FONT="$2"
NEW_FONT="$3"

if [ ! -f "$LATEX_FILE" ]; then
    echo "Error: LaTeX file not found: $LATEX_FILE" >&2
    exit 1
fi

# Replace font name
sed -i.bak -e "s/${OLD_FONT}/${NEW_FONT}/g" "$LATEX_FILE"

# Check if translation may have missed content (warning only, no substitution)
python3 <<PYTHON_EOF
import re
import sys

file_path = '$LATEX_FILE'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Check if TitleEn contains mostly ASCII (English) characters
# Search for newcommand with TitleEn using proper regex escaping
try:
    title_pattern = r'\\\\newcommand\s*\{[^}]*TitleEn[^}]*\}\s*\{([^}]+)\}'
    match = re.search(title_pattern, content, re.DOTALL)
    if match:
        title_content = match.group(1).strip()
        # Check if title is mostly ASCII (likely English)
        if title_content:
            ascii_ratio = sum(1 for c in title_content if ord(c) < 128) / len(title_content)
            if ascii_ratio > 0.7 and len(title_content) > 10:
                sys.stderr.write(f"Warning: Title may still be in English (translation may have failed): {title_content[:50]}...\n")
except Exception:
    pass  # Ignore regex errors, just don't check

# Check for common English labels that should have been translated (simple string search)
if 'Student:' in content and '\\AuthorEn' in content and '學生:' not in content:
    sys.stderr.write("Warning: 'Student:' label appears untranslated\n")
if 'Advisor:' in content and '\\AdvisorEn' in content and '指導教授:' not in content:
    sys.stderr.write("Warning: 'Advisor:' label appears untranslated\n")
PYTHON_EOF

rm -f "${LATEX_FILE}.bak"

