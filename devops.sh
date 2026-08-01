#!/bin/bash
# Development Operations Center
# Merges operations from Makefile and make-docker.sh for streamlined usage
#
# This script handles Docker container management and executes build operations
# directly inside the pandocker container.

set -e

# Base image configuration
BASE_IMAGE_NAME="dalibo/pandocker"
BASE_IMAGE_TAG="latest-full"
BASE_IMAGE="${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"

# Derived image configuration (with jq and curl pre-installed)
DERIVED_IMAGE_NAME="pandocker-with-tools"
DERIVED_IMAGE_TAG="latest"
DERIVED_IMAGE="${DERIVED_IMAGE_NAME}:${DERIVED_IMAGE_TAG}"

# File names (primary EN build)
DATE_SUFFIX="$(date +%Y%m%d)"
PDF="thesis${DATE_SUFFIX}.pdf"
SRC="paper.md"
BIB="references.json"
CSL="chicago-author-date.csl"
COVER_TEX="cover_page.tex"
COVER_PDF="cover.pdf"
RECOMMENDATION_PDF="recommendation_form.pdf"
RECOGNITION_PDF="recognition_form.pdf"
PRINTED_PDF="printed.pdf"
LOGO_FILE="ntust_logo.jpg"
LOGO_URL="https://emrd.ntust.edu.tw/var/file/39/1039/img/2483/LOGO.jpg"
TEMP_SRC="paper.tmp.md"
MERMAID_TEMP_SRC="paper.mermaid.tmp.md"
COVER_TEMP_TEX="cover_page.tmp.tex"

# Translation defaults (overridable in TRANSLATE_CONFIG_FILE, see zh-tw.ini)
LLM_MODEL="gemini-2.5-flash"
TRANSLATE_CONFIG_FILE="zh-tw.ini"

# Get absolute path of current directory
WORK_DIR=$(pwd)
API_KEY_FILE="$WORK_DIR/.api_key"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
}

# Check and pull base image if needed
ensure_base_image() {
    if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${BASE_IMAGE}$"; then
        print_info "Base image ${BASE_IMAGE} not found locally. Pulling..."
        docker pull --platform linux/amd64 "$BASE_IMAGE"
        if [ $? -ne 0 ]; then
            print_error "Failed to pull ${BASE_IMAGE}"
            print_error "Please check your Docker connection and try again."
            exit 1
        fi
    fi
}

# Build derived image if needed
ensure_derived_image() {
    if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${DERIVED_IMAGE}$"; then
        print_info "Derived image ${DERIVED_IMAGE} not found. Building from Dockerfile..."
        if [ ! -f "$WORK_DIR/Dockerfile" ]; then
            print_error "Dockerfile not found in $WORK_DIR"
            print_error "Please create a Dockerfile that extends ${BASE_IMAGE} and installs jq and curl."
            exit 1
        fi
        docker build --platform linux/amd64 -t "$DERIVED_IMAGE" -f "$WORK_DIR/Dockerfile" "$WORK_DIR"
        if [ $? -ne 0 ]; then
            print_error "Failed to build derived image ${DERIVED_IMAGE}"
            exit 1
        fi
        print_info "Derived image built successfully."
    fi
}

# Run command in Docker container
run_in_docker() {
    docker run --rm \
        --entrypoint="" \
        -u "$(id -u):$(id -g)" \
        -v "$WORK_DIR":/workspace \
        -w /workspace \
        "$DERIVED_IMAGE" \
        bash -c "$1"
}

# Build PDF operation
build_pdf() {
    local out_file="${1:-$PDF}"
    print_info "Building PDF: $out_file"
    
    # Process Mermaid diagrams
    print_info "Processing Mermaid diagrams..."
    run_in_docker "mkdir -p images && bash tools/process-mermaid.sh $SRC $MERMAID_TEMP_SRC images"
    
    # Detect and replace fonts
    print_info "Detecting fonts and processing document..."
    run_in_docker "
        CJK_FONT_TC=\$(bash tools/detect-fonts.sh 2>/dev/null | grep '^CJK_FONT_TC=' | cut -d= -f2)
        CJK_FONT_TC=\${CJK_FONT_TC:-AR PL UMing TW}
        echo \"Using CJK font: \$CJK_FONT_TC\"
        bash tools/replace-fonts.sh $MERMAID_TEMP_SRC $TEMP_SRC 'PingFang SC' \"\$CJK_FONT_TC\" 'PingFang TC' \"\$CJK_FONT_TC\"
        pandoc $TEMP_SRC --standalone --filter pandoc-crossref --citeproc --csl=chicago-author-date.csl -M title=\"\" -M author=\"\" -M date=\"\" -o paper.tex
        bash tools/fix-latex-csl.sh paper.tex
        xelatex -interaction=nonstopmode paper.tex 2>&1 | tail -50
        xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1
        if [ -f paper.pdf ]; then
            if [ 'paper.pdf' != '$out_file' ]; then mv paper.pdf '$out_file'; fi
        else
            exit 1
        fi
        bash tools/cleanup-temp.sh $MERMAID_TEMP_SRC $TEMP_SRC
    "
    
    if [ -f "$WORK_DIR/$out_file" ]; then
        print_info "Successfully generated: $out_file"
    else
        print_error "Failed to generate $out_file"
        exit 1
    fi
}

# Build cover page
build_cover() {
    print_info "Building cover page: $COVER_PDF"
    
    # Download logo if missing
    if [ ! -f "$WORK_DIR/$LOGO_FILE" ]; then
        print_info "Fetching NTUST logo..."
        run_in_docker "bash tools/download-logo.sh $LOGO_FILE $LOGO_URL"
    fi
    
    # Build cover PDF
    run_in_docker "
        MAIN_FONT=\$(bash tools/detect-fonts.sh 2>/dev/null | grep '^MAIN_FONT=' | cut -d= -f2)
        MAIN_FONT=\${MAIN_FONT:-Liberation Serif}
        CJK_FONT_TC=\$(bash tools/detect-fonts.sh 2>/dev/null | grep '^CJK_FONT_TC=' | cut -d= -f2)
        CJK_FONT_TC=\${CJK_FONT_TC:-AR PL UMing TW}
        echo \"Using main font: \$MAIN_FONT, CJK font: \$CJK_FONT_TC\"
        bash tools/replace-fonts.sh $COVER_TEX $COVER_TEMP_TEX 'Times New Roman' \"\$MAIN_FONT\" 'PingFang TC' \"\$CJK_FONT_TC\"
        bash tools/inject-date.sh $COVER_TEMP_TEX
        xelatex -interaction=nonstopmode -jobname=cover $COVER_TEMP_TEX
        bash tools/cleanup-temp.sh $COVER_TEMP_TEX
    "
    
    if [ -f "$WORK_DIR/$COVER_PDF" ]; then
        print_info "Successfully generated: $COVER_PDF"
    else
        print_error "Failed to generate $COVER_PDF"
        exit 1
    fi
}

# Build printed version (cover + recommendation form + recognition form + paper)
build_printed() {
    print_info "Building printed version: $PRINTED_PDF"
    
    # Ensure cover and paper PDFs exist
    if [ ! -f "$WORK_DIR/$COVER_PDF" ]; then
        build_cover
    fi
    
    if [ ! -f "$WORK_DIR/$PDF" ]; then
        build_pdf
    fi
    
    # Defensive PDF merge: check for existing form PDFs
    local merge_files=("$COVER_PDF")
    
    if [ -f "$WORK_DIR/$RECOMMENDATION_PDF" ]; then
        print_info "Found recommendation form: $RECOMMENDATION_PDF, adding to merge."
        merge_files+=("$RECOMMENDATION_PDF")
    else
        print_warn "Recommendation form not found: $RECOMMENDATION_PDF. Skipping."
    fi
    
    if [ -f "$WORK_DIR/$RECOGNITION_PDF" ]; then
        print_info "Found recognition form: $RECOGNITION_PDF, adding to merge."
        merge_files+=("$RECOGNITION_PDF")
    else
        print_warn "Recognition form not found: $RECOGNITION_PDF. Skipping."
    fi
    
    merge_files+=("$PDF")
    
    # Merge PDFs: cover + optional recommendation form + optional recognition form + paper
    run_in_docker "bash tools/merge-pdfs.sh ${merge_files[*]} $PRINTED_PDF"
    
    if [ -f "$WORK_DIR/$PRINTED_PDF" ]; then
        print_info "Successfully generated: $PRINTED_PDF"
    else
        print_error "Failed to generate $PRINTED_PDF"
        exit 1
    fi
}

# Minimal INI-file reader: sets each "key = value" line as a same-named shell
# variable. Comments start with ';' or '#'; blank lines and '[section]'
# headers are ignored; surrounding quotes on a value are stripped if present.
load_ini_file() {
    local file="$1"
    local line trimmed key value
    while IFS= read -r line || [ -n "$line" ]; do
        trimmed="${line#"${line%%[![:space:]]*}"}"
        case "$trimmed" in
            ''|'#'*|';'*|'['*) continue ;;
        esac
        [ "${trimmed#*=}" = "$trimmed" ] && continue

        key="${trimmed%%=*}"
        key="${key%"${key##*[![:space:]]}"}"

        value="${trimmed#*=}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        case "$value" in
            \"*\") value="${value#\"}"; value="${value%\"}" ;;
            \'*\') value="${value#\'}"; value="${value%\'}" ;;
        esac

        printf -v "$key" '%s' "$value"
    done < "$file"
}

# Load the translation config into the TR_* variables
load_translate_config() {
    if [ ! -f "$TRANSLATE_CONFIG_FILE" ]; then
        print_error "Translation config not found: $TRANSLATE_CONFIG_FILE"
        exit 1
    fi

    DIR=""; FROM=""; TO=""; MODEL=""; FIGURE_LABEL=""; TABLE_LABEL=""
    load_ini_file "$TRANSLATE_CONFIG_FILE"

    if [ -z "$DIR" ] || [ -z "$FROM" ] || [ -z "$TO" ]; then
        print_error "$TRANSLATE_CONFIG_FILE must set DIR, FROM, and TO"
        exit 1
    fi

    TR_DIR="$DIR"
    TR_FROM="$FROM"
    TR_TO="$TO"
    TR_MODEL="${MODEL:-$LLM_MODEL}"
    TR_FIGURE_LABEL="$FIGURE_LABEL"
    TR_TABLE_LABEL="$TABLE_LABEL"

    TR_SRC="$TR_DIR/paper.md"
    TR_COVER="$TR_DIR/cover_page.tex"
    TR_PDF="$TR_DIR/thesis.pdf"
    TR_COVER_PDF="$TR_DIR/cover.pdf"
    TR_PRINTED_PDF="$TR_DIR/printed.pdf"
}

# Translate main manuscript (Markdown) using the loaded config
translate_markdown() {
    print_info "Translating $SRC to $TR_TO markdown in $TR_DIR/"

    run_in_docker "
        mkdir -p $TR_DIR
        CJK_FONT_TC=\$(bash tools/detect-fonts.sh 2>/dev/null | grep '^CJK_FONT_TC=' | cut -d= -f2)
        CJK_FONT_TC=\${CJK_FONT_TC:-AR PL UMing TW}
        echo 'Translating $SRC to $TR_TO...'
        bash tools/translate.sh $SRC $TR_SRC '$TR_FROM' '$TR_TO' '$TR_MODEL' '.api_key'
        echo 'Validating and fixing formatting errors in translation...'
        bash tools/validate-and-fix-translated-md.sh $SRC $TR_SRC '$TR_MODEL' '.api_key'
        echo 'Post-processing translated markdown...'
        bash tools/postprocess-translated-md.sh $TR_SRC \"\$CJK_FONT_TC\" '$TR_FIGURE_LABEL' '$TR_TABLE_LABEL'
    "
}

# Translate cover LaTeX using the loaded config
translate_cover() {
    print_info "Translating $COVER_TEX to $TR_TO LaTeX in $TR_DIR/"

    run_in_docker "
        mkdir -p $TR_DIR
        CJK_FONT_TC=\$(bash tools/detect-fonts.sh 2>/dev/null | grep '^CJK_FONT_TC=' | cut -d= -f2)
        CJK_FONT_TC=\${CJK_FONT_TC:-AR PL UMing TW}
        echo 'Translating $COVER_TEX to $TR_TO...'
        bash tools/translate.sh $COVER_TEX $TR_COVER '$TR_FROM' '$TR_TO' '$TR_MODEL' '.api_key'
        echo 'Post-processing translated LaTeX...'
        bash tools/postprocess-translated-tex.sh $TR_COVER 'PingFang TC' \"\$CJK_FONT_TC\"
    "
}

# Build translated paper PDF from translated markdown
build_translated_pdf() {
    print_info "Building translated paper PDF: $TR_PDF"

    run_in_docker "
        echo 'Building PDF from translated markdown...'
        echo 'Processing Mermaid diagrams...'
        mkdir -p images
        bash tools/create-symlinks.sh $TR_DIR $BIB $CSL 'bibliography.bib'
        if [ -d images ]; then
            if [ -e $TR_DIR/images ]; then rm -rf $TR_DIR/images; fi
            ( cd $TR_DIR && ln -sf ../images images )
        fi
        bash tools/process-mermaid.sh $TR_SRC $TR_DIR/paper.mermaid.tmp.md images
        CJK_FONT_TC=\$(bash tools/detect-fonts.sh 2>/dev/null | grep '^CJK_FONT_TC=' | cut -d= -f2)
        CJK_FONT_TC=\${CJK_FONT_TC:-AR PL UMing TW}
        echo \"Using CJK font: \$CJK_FONT_TC\"
        bash tools/replace-fonts.sh $TR_DIR/paper.mermaid.tmp.md $TR_DIR/paper.tmp.md 'PingFang SC' \"\$CJK_FONT_TC\"
        ( cd $TR_DIR && pandoc paper.tmp.md --standalone --filter pandoc-crossref --citeproc --csl=chicago-author-date.csl -M title=\"\" -M author=\"\" -M date=\"\" -o paper.tex )
        bash tools/fix-latex-csl.sh $TR_DIR/paper.tex
        ( cd $TR_DIR && xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1 )
        ( cd $TR_DIR && xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1 )
        if [ ! -f '$TR_PDF' ]; then exit 1; fi
        bash tools/cleanup-temp.sh $TR_DIR/paper.mermaid.tmp.md $TR_DIR/paper.tmp.md $TR_DIR/paper.tex $TR_DIR/paper.aux $TR_DIR/paper.log
        echo 'Cleaned up intermediate translation files'
    "

    if [ -f "$WORK_DIR/$TR_PDF" ]; then
        print_info "Successfully generated translated paper PDF: $TR_PDF"
    else
        print_error "Failed to generate $TR_PDF"
        exit 1
    fi
}

# Build translated cover PDF from translated LaTeX
build_translated_cover_pdf() {
    print_info "Building translated cover PDF: $TR_COVER_PDF"

    # Ensure logo exists (reuse main-cover logic)
    if [ ! -f "$WORK_DIR/$LOGO_FILE" ]; then
        print_info "Fetching NTUST logo..."
        run_in_docker "bash tools/download-logo.sh $LOGO_FILE $LOGO_URL"
    fi

    run_in_docker "
        echo 'Building cover PDF from translated LaTeX...'
        MAIN_FONT=\$(bash tools/detect-fonts.sh 2>/dev/null | grep '^MAIN_FONT=' | cut -d= -f2)
        MAIN_FONT=\${MAIN_FONT:-Liberation Serif}
        CJK_FONT_TC=\$(bash tools/detect-fonts.sh 2>/dev/null | grep '^CJK_FONT_TC=' | cut -d= -f2)
        CJK_FONT_TC=\${CJK_FONT_TC:-AR PL UMing TW}
        echo \"Using main font: \$MAIN_FONT, CJK font: \$CJK_FONT_TC\"
        bash tools/copy-logo.sh $LOGO_FILE $TR_DIR
        bash tools/replace-fonts.sh $TR_COVER $TR_DIR/cover_page.tmp.tex 'Times New Roman' \"\$MAIN_FONT\" 'PingFang TC' \"\$CJK_FONT_TC\"
        bash tools/inject-date.sh $TR_DIR/cover_page.tmp.tex
        ( cd $TR_DIR && xelatex -interaction=nonstopmode -jobname=cover cover_page.tmp.tex )
        bash tools/cleanup-temp.sh $TR_DIR/cover_page.tmp.tex $TR_DIR/cover.aux $TR_DIR/cover.log
        echo 'Cleaned up intermediate translation files'
    "

    if [ -f "$WORK_DIR/$TR_COVER_PDF" ]; then
        print_info "Successfully generated translated cover PDF: $TR_COVER_PDF"
    else
        print_error "Failed to generate $TR_COVER_PDF"
        exit 1
    fi
}

# Merge translated cover + paper into printed PDF
build_translated_printed() {
    print_info "Merging translated cover + paper into: $TR_PRINTED_PDF"

    if [ ! -f "$WORK_DIR/$TR_COVER_PDF" ]; then
        build_translated_cover_pdf
    fi

    if [ ! -f "$WORK_DIR/$TR_PDF" ]; then
        build_translated_pdf
    fi

    run_in_docker "bash tools/merge-pdfs.sh $TR_COVER_PDF $TR_PDF $TR_PRINTED_PDF"

    if [ -f "$WORK_DIR/$TR_PRINTED_PDF" ]; then
        print_info "Successfully generated: $TR_PRINTED_PDF"
    else
        print_error "Failed to generate $TR_PRINTED_PDF"
        exit 1
    fi
}

# Run the translation pipeline, optionally limited to a single step
run_translate() {
    local step="${1:-all}"

    load_translate_config
    print_info "Translation config: $TRANSLATE_CONFIG_FILE ($TR_FROM -> $TR_TO, dir: $TR_DIR)"

    # Require API key file before running translation operations
    if [ ! -f "$API_KEY_FILE" ]; then
        print_error "API key file not found: $API_KEY_FILE"
        print_error "Create it with your Gemini API key before running translate."
        echo "Example: echo \"<your-key>\" > .api_key && chmod 600 .api_key" >&2
        exit 1
    fi

    case "$step" in
        all)
            translate_markdown
            translate_cover
            build_translated_pdf
            build_translated_cover_pdf
            build_translated_printed
            ;;
        markdown) translate_markdown ;;
        cover) translate_cover ;;
        pdf) build_translated_pdf ;;
        cover_pdf) build_translated_cover_pdf ;;
        printed) build_translated_printed ;;
        *)
            print_error "Unknown step: $step"
            print_error "Valid steps: all, markdown, cover, pdf, cover_pdf, printed"
            exit 1
            ;;
    esac

    print_info "Translation step '$step' completed. Output in $TR_DIR/"
}

# Clean generated files
clean() {
    print_info "Cleaning generated files..."
    run_in_docker "bash tools/clean.sh paper.pdf $PDF $COVER_PDF $PRINTED_PDF $TEMP_SRC $COVER_TEMP_TEX"
    run_in_docker "rm -f thesis[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].pdf 2>/dev/null || true"
    run_in_docker "rm -f ref_list.md 2>/dev/null || true"
    run_in_docker "rm -f toc_list.md 2>/dev/null || true"
    run_in_docker "rm -f images/mermaid-*.png 2>/dev/null || true"
    run_in_docker "rm -f $MERMAID_TEMP_SRC 2>/dev/null || true"
    if [ -f "$TRANSLATE_CONFIG_FILE" ]; then
        ( DIR=""; load_ini_file "$TRANSLATE_CONFIG_FILE"; if [ -n "$DIR" ]; then run_in_docker "rm -rf $DIR 2>/dev/null || true"; fi )
    fi
    print_info "Clean complete"
}

# Generate .tags from all Markdown files (for editor navigation)
build_tags() {
    print_info "Generating .tags from all Markdown files..."
    run_in_docker "find . -name '*.md' -type f ! -path './.git/*' | sort > .tags"
    if [ -f "$WORK_DIR/.tags" ]; then
        COUNT=$(wc -l < "$WORK_DIR/.tags")
        print_info "Successfully generated .tags ($COUNT Markdown files)"
    else
        print_error "Failed to generate .tags"
        exit 1
    fi
}

# Extract references list from Markdown and copy to clipboard
# pdf_file may point into a translation output dir (e.g. zh_tw/printed.pdf);
# the reference list is then generated alongside it in that same directory.
ref_list() {
    local pdf_file="${1:-$PRINTED_PDF}"
    local out_dir
    out_dir=$(dirname "$pdf_file")
    local ref_md="ref_list.md"

    if [ "$out_dir" != "." ]; then
        ref_md="$out_dir/ref_list.md"
    fi

    print_info "Generating reference list: $ref_md..."
    if [ "$out_dir" != "." ]; then
        run_in_docker "
            mkdir -p $out_dir
            bash tools/create-symlinks.sh $out_dir $BIB $CSL 'bibliography.bib'
            python3 tools/extract-references-pandoc.py $out_dir/paper.md $out_dir/ref_list.md
        "
    else
        run_in_docker "python3 tools/extract-references-pandoc.py $SRC ref_list.md"
    fi
    
    if [ -f "$WORK_DIR/$ref_md" ]; then
        print_info "Copying references from $ref_md to clipboard..."
        python3 -c "
import sys, subprocess, os
with open(\"$WORK_DIR/$ref_md\", 'r', encoding='utf-8') as f:
    content = f.read()
lines = content.split('\n')
if lines and lines[0].startswith('# '):
    content = '\n'.join(lines[2:])
copied = False
if sys.platform == 'darwin':
    p = subprocess.Popen(['pbcopy'], stdin=subprocess.PIPE, text=True)
    p.communicate(input=content)
    copied = True
elif sys.platform == 'win32':
    p = subprocess.Popen(['clip'], stdin=subprocess.PIPE, text=True)
    p.communicate(input=content)
    copied = True
else:
    try:
        if os.path.exists('/proc/version'):
            with open('/proc/version', 'r') as f:
                if 'microsoft' in f.read().lower():
                    p = subprocess.Popen(['clip.exe'], stdin=subprocess.PIPE, text=True)
                    p.communicate(input=content)
                    copied = True
    except:
        pass
    if not copied:
        for tool in [['xclip', '-selection', 'clipboard'], ['xsel', '--clipboard', '--input']]:
            try:
                p = subprocess.Popen(tool, stdin=subprocess.PIPE, text=True)
                p.communicate(input=content)
                copied = True
                break
            except:
                continue
if copied:
    print('Successfully copied references to clipboard!')
    print('\n--- Preview of Copied References (First 10 lines) ---')
    ref_lines = content.split('\n')
    for line in ref_lines[:10]:
        print(line)
    print('...')
else:
    print('Failed to copy to clipboard automatically.')
"
    else
        print_error "Failed to generate $ref_md"
        exit 1
    fi
}

# Extract table of contents from PDF and copy to clipboard
toc_list() {
    local pdf_file="${1:-$PRINTED_PDF}"
    local out_dir
    out_dir=$(dirname "$pdf_file")
    local toc_md="toc_list.md"

    if [ "$out_dir" != "." ]; then
        toc_md="$out_dir/toc_list.md"
    fi

    if [ ! -f "$WORK_DIR/$pdf_file" ]; then
        print_error "PDF file not found: $pdf_file"
        print_error "Please build it first using './devops.sh printed' or specify another PDF."
        exit 1
    fi
    
    print_info "Generating table of contents: $toc_md..."
    python3 tools/extract-toc.py "$WORK_DIR/$pdf_file" "$WORK_DIR/$toc_md"
}

# Install dependencies (informational only)
deps() {
    print_info "Note: This operation is for local development."
    print_info "In Docker, all tools are pre-installed."
    print_info "If you want to install dependencies locally, run: bash tools/deps.sh"
}

# Show help
show_help() {
    cat <<EOF
Development Operations Center - devops.sh

Usage: ./devops.sh [operation]

Available operations:
  help                     - Show this help message [default]
  pdf                      - Build the main paper PDF (paper.pdf)
  pdf_date                 - Build the paper PDF with date suffix
  cover                    - Build the cover page PDF
  printed                  - Build the printed version (cover + paper)
  translate [step]         - Run the translation pipeline (see zh-tw.ini)
  tags                     - Generate .tags from all Markdown files
  ref-list                - Extract references from PDF and copy to clipboard
  toc-list                - Extract table of contents from PDF and copy to clipboard
  clean                    - Remove all generated files
  deps                     - Show information about dependencies

Examples:
  ./devops.sh                        # Show this help message
  ./devops.sh pdf                    # Build paper.pdf
  ./devops.sh pdf_date               # Build thesisYYYYMMDD.pdf
  ./devops.sh cover                  # Build only the cover page
  ./devops.sh translate               # Run the full translation pipeline
  ./devops.sh translate pdf           # Rebuild only the translated paper PDF
  ./devops.sh ref-list                # Extract and copy references
  ./devops.sh toc-list                # Extract and copy table of contents
  ./devops.sh clean                   # Clean all generated files

Translation config lives in zh-tw.ini at the repo root (see comments in that
file for the full key list and available steps).

Note: All builds run inside Docker container (pandocker-with-tools)
EOF
}

# Main script logic
main() {
    # Default operation is 'help'
    OPERATION="${1:-help}"

    # Handle help immediately without Docker checks
    case "$OPERATION" in
        help|--help|-h)
            show_help
            return 0
            ;;
    esac

    # Check Docker availability
    check_docker
    
    # Ensure Docker images are ready
    ensure_base_image
    ensure_derived_image
    
    case "$OPERATION" in
        pdf)
            build_pdf "paper.pdf"
            ;;
        pdf_date)
            build_pdf "$PDF"
            ;;
        cover)
            build_cover
            ;;
        printed)
            build_printed
            ;;
        translate)
            run_translate "$2"
            ;;
        tags)
            build_tags
            ;;
        ref-list|ref_list)
            ref_list "$2"
            ;;
        toc-list|toc_list)
            toc_list "$2"
            ;;
        clean)
            clean
            ;;
        deps)
            deps
            ;;
        *)
            print_error "Unknown operation: $OPERATION"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
