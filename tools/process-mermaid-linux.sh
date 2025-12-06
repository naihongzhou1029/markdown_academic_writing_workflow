#!/bin/bash
# Process Mermaid code blocks in Markdown files
# Converts Mermaid diagrams to PNG images and replaces code blocks with image references

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <input_file> <output_file> [images_dir]" >&2
    echo "Example: $0 input.md output.md images" >&2
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"
IMAGES_DIR="${3:-images}"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE" >&2
    exit 1
fi

# Ensure images directory exists
mkdir -p "$IMAGES_DIR"

# Check if mmdc is available
if ! command -v mmdc &> /dev/null; then
    echo "Error: mmdc (mermaid-cli) not found. Please install @mermaid-js/mermaid-cli" >&2
    exit 1
fi

# Temporary file for processing
TEMP_FILE=$(mktemp)
trap "rm -f '$TEMP_FILE'" EXIT

# Counter for sequential naming
MERMAID_COUNTER=0

# Process the file line by line
IN_MERMAID_BLOCK=0
MERMAID_CONTENT=""
MERMAID_START_LINE=""

while IFS= read -r line || [ -n "$line" ]; do
    # Check for start of Mermaid block
    if [[ "$line" =~ ^\`\`\`mermaid ]]; then
        IN_MERMAID_BLOCK=1
        MERMAID_CONTENT=""
        MERMAID_START_LINE="$line"
        continue
    fi
    
    # Check for end of Mermaid block
    if [ "$IN_MERMAID_BLOCK" -eq 1 ] && [[ "$line" =~ ^\`\`\` ]]; then
        IN_MERMAID_BLOCK=0
        
        # Generate filename
        MERMAID_COUNTER=$((MERMAID_COUNTER + 1))
        IMAGE_FILENAME="mermaid-${MERMAID_COUNTER}.png"
        IMAGE_PATH="${IMAGES_DIR}/${IMAGE_FILENAME}"
        
        # Create temporary .mmd file
        TEMP_MMD=$(mktemp --suffix=.mmd)
        echo "$MERMAID_CONTENT" > "$TEMP_MMD"
        
        # Use Puppeteer config file with executablePath and Docker-compatible args
        # Prefer the system config created in the image; fall back to a temp config
        if [ -f /etc/puppeteer-config.json ]; then
            TEMP_PUPPETEER_CONFIG=/etc/puppeteer-config.json
            CLEANUP_PUPPETEER_CONFIG=0
        else
            TEMP_PUPPETEER_CONFIG=$(mktemp --suffix=.json)
            echo '{"args": ["--no-sandbox", "--disable-setuid-sandbox"]}' > "$TEMP_PUPPETEER_CONFIG"
            CLEANUP_PUPPETEER_CONFIG=1
        fi
        
        # Convert Mermaid to PNG
        ERROR_LOG=$(mktemp)
        if mmdc -i "$TEMP_MMD" -o "$IMAGE_PATH" -t dark -b transparent \
           -p "$TEMP_PUPPETEER_CONFIG" > "$ERROR_LOG" 2>&1; then
            # Replace with image reference
            echo "![Mermaid diagram]($IMAGE_PATH)" >> "$TEMP_FILE"
            echo "" >> "$TEMP_FILE"
        else
            # If conversion fails, show the actual error
            echo "Warning: Failed to convert Mermaid diagram to image. Keeping original code block." >&2
            if [ -s "$ERROR_LOG" ]; then
                echo "Error details:" >&2
                cat "$ERROR_LOG" >&2
            fi
            echo "$MERMAID_START_LINE" >> "$TEMP_FILE"
            echo "$MERMAID_CONTENT" >> "$TEMP_FILE"
            echo "$line" >> "$TEMP_FILE"
        fi
        
        # Clean up temp files
        rm -f "$TEMP_MMD" "$ERROR_LOG"
        if [ "${CLEANUP_PUPPETEER_CONFIG:-0}" -eq 1 ]; then
            rm -f "$TEMP_PUPPETEER_CONFIG"
        fi
        
        MERMAID_CONTENT=""
        continue
    fi
    
    # Collect content inside Mermaid block
    if [ "$IN_MERMAID_BLOCK" -eq 1 ]; then
        if [ -z "$MERMAID_CONTENT" ]; then
            MERMAID_CONTENT="$line"
        else
            MERMAID_CONTENT="${MERMAID_CONTENT}"$'\n'"${line}"
        fi
        continue
    fi
    
    # Regular line - output as-is
    echo "$line" >> "$TEMP_FILE"
done < "$INPUT_FILE"

# Handle case where file ends while still in Mermaid block
if [ "$IN_MERMAID_BLOCK" -eq 1 ]; then
    echo "Warning: Unclosed Mermaid code block detected. Keeping original block." >&2
    echo "$MERMAID_START_LINE" >> "$TEMP_FILE"
    echo "$MERMAID_CONTENT" >> "$TEMP_FILE"
    echo '```' >> "$TEMP_FILE"
fi

# Move temp file to output
mv "$TEMP_FILE" "$OUTPUT_FILE"

if [ "$MERMAID_COUNTER" -gt 0 ]; then
    echo "Processed $MERMAID_COUNTER Mermaid diagram(s)"
fi

