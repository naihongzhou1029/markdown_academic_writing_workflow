#!/bin/bash
# Translation script for Linux using Gemini API

set -e

# Parse arguments
INPUT_FILE="$1"
OUTPUT_FILE="$2"
SOURCE_LANG="$3"
TARGET_LANG="$4"
MODEL="$5"
API_KEY_FILE="$6"

if [ $# -ne 6 ]; then
    echo "Usage: $0 <input_file> <output_file> <source_lang> <target_lang> <model> <api_key_file>" >&2
    exit 1
fi

# Check if API key file exists; fail fast in non-interactive mode
if [ ! -f "$API_KEY_FILE" ]; then
    echo "Error: API key file not found: $API_KEY_FILE" >&2
    echo "Create this file with your Gemini API key before running translation." >&2
    echo "Example: echo \"<your-key>\" > $API_KEY_FILE && chmod 600 $API_KEY_FILE" >&2
    exit 1
fi

API_KEY=$(cat "$API_KEY_FILE")

# Check for required tools and install if missing (works for root or sudo)
if ! command -v curl &> /dev/null; then
    echo "curl not found. Installing curl..." >&2
    if command -v apt-get &> /dev/null; then
        if [ "$(id -u)" -eq 0 ]; then
            apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq curl >/dev/null 2>&1
        elif command -v sudo &> /dev/null; then
            sudo apt-get update -qq >/dev/null 2>&1 && sudo apt-get install -y -qq curl >/dev/null 2>&1
        else
            echo "Error: curl is required but not installed. Running as non-root without sudo." >&2
            exit 1
        fi
        if [ $? -ne 0 ]; then
            echo "Error: Failed to install curl. Please install it manually." >&2
            exit 1
        fi
    else
        echo "Error: curl is required but not installed and apt-get is not available." >&2
        exit 1
    fi
fi

if ! command -v jq &> /dev/null; then
    echo "jq not found. Installing jq..." >&2
    if command -v apt-get &> /dev/null; then
        if [ "$(id -u)" -eq 0 ]; then
            apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq jq >/dev/null 2>&1
        elif command -v sudo &> /dev/null; then
            sudo apt-get update -qq >/dev/null 2>&1 && sudo apt-get install -y -qq jq >/dev/null 2>&1
        else
            echo "Error: jq is required but not installed. Running as non-root without sudo." >&2
            exit 1
        fi
        if [ $? -ne 0 ]; then
            echo "Error: Failed to install jq. Please install it manually." >&2
            exit 1
        fi
    else
        echo "Error: jq is required but not installed and apt-get is not available." >&2
        exit 1
    fi
fi

# Read input file
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE" >&2
    exit 1
fi

INPUT_CONTENT=$(cat "$INPUT_FILE")

# Determine file type for prompt customization
FILE_EXT="${INPUT_FILE##*.}"
if [ "$FILE_EXT" = "md" ]; then
    PRESERVE_INSTRUCTIONS="Preserve all YAML metadata block structure EXACTLY, including all indentation, spacing, and formatting. CRITICAL: Maintain the exact same indentation for multiline YAML blocks (e.g., the |- block). Also preserve citation syntax (e.g., [@citation_key]), cross-reference syntax (e.g., @tbl:label, @fig:label, @eq:label), and Markdown formatting. Translate reference labels like 'Figure' to '圖', 'Table' to '表格', 'Tab.' to '表'."
elif [ "$FILE_EXT" = "tex" ]; then
    PRESERVE_INSTRUCTIONS="Preserve all LaTeX commands, structure, and formatting. CRITICAL: Translate ALL English text content, including text inside \\newcommand definitions (e.g., translate the content within \\newcommand{\\TitleEn}{...}, \\newcommand{\\AuthorEn}{...}, etc.), labels like 'Student:', 'Advisor:', 'Student ID:', and any other English text. Keep all LaTeX syntax, command names, and structure intact - only translate the actual text content."
else
    PRESERVE_INSTRUCTIONS="Preserve all formatting and structure."
fi

# Construct prompt
if [ "$FILE_EXT" = "tex" ]; then
    PROMPT="Translate the following LaTeX file from $SOURCE_LANG to $TARGET_LANG. $PRESERVE_INSTRUCTIONS Maintain the exact same document structure and formatting. Translate ALL natural language text content including: titles, names, labels, comments, and any text within command definitions. IMPORTANT: Return ONLY the LaTeX code, do NOT wrap it in markdown code fences or add any markdown formatting.

Content to translate:
$INPUT_CONTENT"
else
    PROMPT="Translate the following content from $SOURCE_LANG to $TARGET_LANG. $PRESERVE_INSTRUCTIONS Maintain the exact same document structure and formatting. Only translate the natural language text content.

Content to translate:
$INPUT_CONTENT"
fi

# Create JSON payload
JSON_PAYLOAD=$(jq -n \
    --arg prompt "$PROMPT" \
    '{
        "contents": [{
            "parts": [{
                "text": $prompt
            }]
        }]
    }')

# Call Gemini API
API_URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${API_KEY}"

RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

# Check for API errors
if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // .error')
    echo "Error: Gemini API returned an error: $ERROR_MSG" >&2
    exit 1
fi

# Extract translated text
TRANSLATED_TEXT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty')

if [ -z "$TRANSLATED_TEXT" ]; then
    echo "Error: No translation returned from API" >&2
    echo "Response: $RESPONSE" >&2
    exit 1
fi

# Remove markdown code fences if present (LLM sometimes wraps code in ```language blocks)
if [ "$FILE_EXT" = "tex" ] || [ "$FILE_EXT" = "md" ]; then
    # Check if text starts with code fence and remove first line if so
    FIRST_LINE=$(echo "$TRANSLATED_TEXT" | head -n1)
    if echo "$FIRST_LINE" | grep -qE '^```[a-zA-Z]*$|^```$'; then
        TRANSLATED_TEXT=$(echo "$TRANSLATED_TEXT" | tail -n +2)
    fi
    # Check if text ends with code fence and remove last line if so
    # Use sed to remove last line (works on both macOS and Linux)
    LAST_LINE=$(echo "$TRANSLATED_TEXT" | tail -n1)
    if echo "$LAST_LINE" | grep -qE '^```$'; then
        TRANSLATED_TEXT=$(echo "$TRANSLATED_TEXT" | sed '$d')
    fi
    # Trim any leading/trailing whitespace
    TRANSLATED_TEXT=$(echo "$TRANSLATED_TEXT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
fi

# Create output directory if needed
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# Write translated content to output file
echo "$TRANSLATED_TEXT" > "$OUTPUT_FILE"

echo "Translation completed: $OUTPUT_FILE"

