#!/bin/bash
# Validate and fix formatting errors in translated markdown using AI
# This script reviews the translated markdown file for structural issues
# like malformed tables, broken links, or corrupted syntax

set -e

if [ $# -ne 4 ]; then
    echo "Usage: $0 <original_md_file> <translated_md_file> <llm_model> <api_key_file>" >&2
    exit 1
fi

ORIGINAL_MD="$1"
TRANSLATED_MD="$2"
LLM_MODEL="$3"
API_KEY_FILE="$4"

if [ ! -f "$ORIGINAL_MD" ]; then
    echo "Error: Original markdown file not found: $ORIGINAL_MD" >&2
    exit 1
fi

if [ ! -f "$TRANSLATED_MD" ]; then
    echo "Error: Translated markdown file not found: $TRANSLATED_MD" >&2
    exit 1
fi

if [ ! -f "$API_KEY_FILE" ]; then
    echo "Error: API key file not found: $API_KEY_FILE" >&2
    exit 1
fi

API_KEY=$(cat "$API_KEY_FILE")
if [ -z "$API_KEY" ]; then
    echo "Error: API key file is empty" >&2
    exit 1
fi

# Get base model name without provider prefix
case "$LLM_MODEL" in
    gemini-*)
        PROVIDER="gemini"
        MODEL_NAME="$LLM_MODEL"
        ;;
    *)
        echo "Error: Unsupported LLM model: $LLM_MODEL" >&2
        exit 1
        ;;
esac

echo "Validating and fixing formatting in translated markdown using $LLM_MODEL..."

# Read the original and translated files
ORIGINAL_CONTENT=$(cat "$ORIGINAL_MD")
TRANSLATED_CONTENT=$(cat "$TRANSLATED_MD")

# Create validation prompt
VALIDATION_PROMPT="You are a Markdown formatting validator and fixer. Compare the original English markdown with its translation and fix any structural/formatting errors in the translation.

CRITICAL RULES:
1. Check table structure: Ensure separator rows (with dashes) are present between header and data rows
2. Verify all tables have proper pipe alignment: | Header | Header |
3. Ensure code blocks have proper fencing: every \`\`\`mermaid or \`\`\`bash MUST have a matching closing \`\`\`
4. Check that cross-references like @fig:id, @tbl:id, @eq:id are preserved
5. Verify citation syntax like [@key] remains intact
6. Ensure YAML front matter structure is valid
7. Check that all links and image references are preserved
8. NEVER remove closing code block fences (\`\`\`)

DO NOT:
- Translate any text back to English
- Change the meaning or wording of the translation
- Modify YAML metadata values, citation keys, or reference IDs
- Add or remove content

ONLY fix structural/formatting errors like:
- Malformed table separator rows
- Broken pipe alignment in tables
- Missing code block fences
- Corrupted YAML syntax

Original markdown (English):
---
$ORIGINAL_CONTENT
---

Translated markdown (to be validated and fixed):
---
$TRANSLATED_CONTENT
---

Output ONLY the corrected markdown content, with no explanations or comments. If there are no errors, output the translated markdown as-is."

# Escape the prompt for JSON
ESCAPED_PROMPT=$(echo "$VALIDATION_PROMPT" | jq -Rs .)

# Call the LLM API based on provider
case "$PROVIDER" in
    gemini)
        RESPONSE=$(curl -s -X POST \
            "https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent?key=${API_KEY}" \
            -H "Content-Type: application/json" \
            -d "{
                \"contents\": [{
                    \"parts\": [{
                        \"text\": ${ESCAPED_PROMPT}
                    }]
                }],
                \"generationConfig\": {
                    \"temperature\": 0.1,
                    \"topK\": 1,
                    \"topP\": 1,
                    \"maxOutputTokens\": 32768
                }
            }")
        
        # Extract the corrected content
        CORRECTED_CONTENT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty')
        
        if [ -z "$CORRECTED_CONTENT" ]; then
            echo "Error: Failed to validate and fix markdown. API response:" >&2
            echo "$RESPONSE" | jq . >&2
            exit 1
        fi
        ;;
esac

# Remove markdown code fences if the LLM wrapped the output (only at start/end, not internal ones)
# First, check if content starts/ends with code fences (indicating LLM wrapped the entire output)
FIRST_LINE=$(echo "$CORRECTED_CONTENT" | head -n1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
LAST_LINE=$(echo "$CORRECTED_CONTENT" | tail -n1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Remove wrapping fences only if they're at the very start and end
if echo "$FIRST_LINE" | grep -qE '^```(markdown)?$' && echo "$LAST_LINE" | grep -qE '^```$'; then
    # Remove first and last lines (the wrapping fences)
    CORRECTED_CONTENT=$(echo "$CORRECTED_CONTENT" | sed '1d' | sed '$d')
    # Trim leading/trailing whitespace
    CORRECTED_CONTENT=$(echo "$CORRECTED_CONTENT" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')
fi

# Post-process to ensure code fence balance (critical fix for missing closing backticks)
export CORRECTED_CONTENT_FILE=$(mktemp)
echo "$CORRECTED_CONTENT" > "$CORRECTED_CONTENT_FILE"

python3 <<'PYTHON_EOF'
import sys
import os
import re

content_file = os.environ['CORRECTED_CONTENT_FILE']

with open(content_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

result = []
i = 0
opening_fence_line = None
opening_fence_type = None

while i < len(lines):
    line = lines[i]
    
    # Check for opening code fence
    opening_match = re.match(r'^```(\w*)\s*$', line.rstrip())
    if opening_match:
        # Found opening fence
        opening_fence_line = i
        opening_fence_type = opening_match.group(1) or 'generic'
        result.append(line)
        i += 1
        continue
    
    # Check for closing code fence
    if re.match(r'^```\s*$', line.rstrip()):
        # Found closing fence
        if opening_fence_line is not None:
            # Properly closed, reset
            opening_fence_line = None
            opening_fence_type = None
        result.append(line)
        i += 1
        continue
    
    # Check if we're inside an unclosed code block (at end of file)
    if i == len(lines) - 1 and opening_fence_line is not None:
        # Missing closing fence! Add it before the last line if it's not empty
        # or add it as a new line
        if line.strip():  # Last line has content
            result.append(line)
            result.append('```\n')
        else:  # Last line is empty
            result.append('```\n')
            result.append(line)
        break
    
    result.append(line)
    i += 1

# Check if we still have an unclosed block at the end
if opening_fence_line is not None:
    # Find the last non-empty line and add closing fence after it
    # Or if file ends with empty lines, add before them
    last_non_empty = len(result) - 1
    while last_non_empty >= 0 and not result[last_non_empty].strip():
        last_non_empty -= 1
    
    if last_non_empty >= 0:
        # Insert closing fence after last non-empty line
        result.insert(last_non_empty + 1, '```\n')
    else:
        # All lines empty, just append
        result.append('```\n')

# Remove trailing empty lines but keep one if needed
while len(result) > 0 and result[-1].strip() == '':
    result.pop()

with open(content_file, 'w', encoding='utf-8') as f:
    f.writelines(result)
PYTHON_EOF

CORRECTED_CONTENT=$(cat "$CORRECTED_CONTENT_FILE")
rm -f "$CORRECTED_CONTENT_FILE"

# Write the corrected content back to the translated file
echo "$CORRECTED_CONTENT" > "$TRANSLATED_MD"

echo "Validation and fixes applied successfully."

