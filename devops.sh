#!/bin/bash
# Development Operations Center
# Merges operations from Makefile and make-docker.sh for streamlined usage
#
# This script handles Docker container management and executes build targets
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
RECOGNITION_PDF="recognition_form.pdf"
EXAMINATION_PDF="examination_committee.pdf"
PRINTED_PDF="Thesis-乃宏-FinalVersion.pdf"
LOGO_FILE="ntust_logo.jpg"
LOGO_URL="https://emrd.ntust.edu.tw/var/file/39/1039/img/2483/LOGO.jpg"
TEMP_SRC="paper.tmp.md"
MERMAID_TEMP_SRC="paper.mermaid.tmp.md"
COVER_TEMP_TEX="cover_page.tmp.tex"

# Translation / zh_tw paths
LLM_MODEL="gemini-2.5-flash"
ZH_TW_DIR="zh_tw"
ZH_TW_SRC="$ZH_TW_DIR/paper.md"
ZH_TW_COVER="$ZH_TW_DIR/cover_page.tex"
ZH_TW_PDF="$ZH_TW_DIR/thesis.pdf"
ZH_TW_COVER_PDF="$ZH_TW_DIR/cover.pdf"
ZH_TW_PRINTED_PDF="$ZH_TW_DIR/Thesis-乃宏-FinalVersion.pdf"

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

# Build PDF target
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
        pandoc $TEMP_SRC --standalone --filter pandoc-crossref --citeproc --bibliography=bibliography.bib --csl=chicago-author-date.csl -M title=\"\" -M author=\"\" -M date=\"\" -o paper.tex
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

# Build printed version (cover + recognition form + paper)
build_printed() {
    print_info "Building printed version: $PRINTED_PDF"
    
    # Ensure cover and paper PDFs exist
    if [ ! -f "$WORK_DIR/$COVER_PDF" ]; then
        build_cover
    fi
    
    if [ ! -f "$WORK_DIR/$PDF" ]; then
        build_pdf
    fi
    
    # Ensure recognition form exists
    if [ ! -f "$WORK_DIR/$RECOGNITION_PDF" ]; then
        print_error "Recognition form PDF not found: $RECOGNITION_PDF"
        exit 1
    fi
    
    # Ensure examination committee form exists
    if [ ! -f "$WORK_DIR/$EXAMINATION_PDF" ]; then
        print_error "Examination committee PDF not found: $EXAMINATION_PDF"
        exit 1
    fi
    
    # Merge PDFs: cover + recognition form + examination committee + paper
    run_in_docker "bash tools/merge-pdfs.sh $COVER_PDF $RECOGNITION_PDF $EXAMINATION_PDF $PDF $PRINTED_PDF"
    
    if [ -f "$WORK_DIR/$PRINTED_PDF" ]; then
        print_info "Successfully generated: $PRINTED_PDF"
    else
        print_error "Failed to generate $PRINTED_PDF"
        exit 1
    fi
}

# Translate main manuscript to Traditional Chinese (Markdown)
translate_zh_tw_markdown() {
    print_info "Translating $SRC to Traditional Chinese markdown in $ZH_TW_DIR/"

    run_in_docker "
        mkdir -p $ZH_TW_DIR
        CJK_FONT_TC=\$(bash tools/detect-fonts.sh 2>/dev/null | grep '^CJK_FONT_TC=' | cut -d= -f2)
        CJK_FONT_TC=\${CJK_FONT_TC:-AR PL UMing TW}
        echo 'Translating $SRC to Traditional Chinese...'
        bash tools/translate.sh $SRC $ZH_TW_SRC 'English' 'Traditional Chinese' '$LLM_MODEL' '.api_key'
        echo 'Validating and fixing formatting errors in translation...'
        bash tools/validate-and-fix-translated-md.sh $SRC $ZH_TW_SRC '$LLM_MODEL' '.api_key'
        echo 'Post-processing translated markdown...'
        bash tools/postprocess-translated-md.sh $ZH_TW_SRC \"\$CJK_FONT_TC\"
    "
}

# Translate cover LaTeX to Traditional Chinese
translate_zh_tw_cover() {
    print_info "Translating $COVER_TEX to Traditional Chinese LaTeX in $ZH_TW_DIR/"

    run_in_docker "
        mkdir -p $ZH_TW_DIR
        CJK_FONT_TC=\$(bash tools/detect-fonts.sh 2>/dev/null | grep '^CJK_FONT_TC=' | cut -d= -f2)
        CJK_FONT_TC=\${CJK_FONT_TC:-AR PL UMing TW}
        echo 'Translating $COVER_TEX to Traditional Chinese...'
        bash tools/translate.sh $COVER_TEX $ZH_TW_COVER 'English' 'Traditional Chinese' '$LLM_MODEL' '.api_key'
        echo 'Post-processing translated LaTeX...'
        bash tools/postprocess-translated-tex.sh $ZH_TW_COVER 'PingFang TC' \"\$CJK_FONT_TC\"
    "
}

# Build zh_tw paper PDF from translated markdown
build_zh_tw_pdf() {
    print_info "Building zh_tw paper PDF: $ZH_TW_PDF"

    run_in_docker "
        echo 'Building PDF from translated markdown...'
        echo 'Processing Mermaid diagrams...'
        mkdir -p images
        bash tools/create-symlinks.sh $ZH_TW_DIR $BIB $CSL 'bibliography.bib'
        if [ -d images ]; then
            if [ -e $ZH_TW_DIR/images ]; then rm -rf $ZH_TW_DIR/images; fi
            ( cd $ZH_TW_DIR && ln -sf ../images images )
        fi
        bash tools/process-mermaid.sh $ZH_TW_SRC $ZH_TW_DIR/paper.mermaid.tmp.md images
        CJK_FONT_TC=\$(bash tools/detect-fonts.sh 2>/dev/null | grep '^CJK_FONT_TC=' | cut -d= -f2)
        CJK_FONT_TC=\${CJK_FONT_TC:-AR PL UMing TW}
        echo \"Using CJK font: \$CJK_FONT_TC\"
        bash tools/replace-fonts.sh $ZH_TW_DIR/paper.mermaid.tmp.md $ZH_TW_DIR/paper.tmp.md 'PingFang SC' \"\$CJK_FONT_TC\"
        ( cd $ZH_TW_DIR && pandoc paper.tmp.md --standalone --filter pandoc-crossref --citeproc --bibliography=references.json --bibliography='bibliography.bib' --csl=chicago-author-date.csl -M title=\"\" -M author=\"\" -M date=\"\" -o paper.tex )
        bash tools/fix-latex-csl.sh $ZH_TW_DIR/paper.tex
        ( cd $ZH_TW_DIR && xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1 )
        ( cd $ZH_TW_DIR && xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1 )
        if [ ! -f '$ZH_TW_PDF' ]; then exit 1; fi
        bash tools/cleanup-temp.sh $ZH_TW_DIR/paper.mermaid.tmp.md $ZH_TW_DIR/paper.tmp.md $ZH_TW_DIR/paper.tex $ZH_TW_DIR/paper.aux $ZH_TW_DIR/paper.log
        echo 'Cleaned up intermediate translation files'
    "

    if [ -f "$WORK_DIR/$ZH_TW_PDF" ]; then
        print_info "Successfully generated zh_tw paper PDF: $ZH_TW_PDF"
    else
        print_error "Failed to generate $ZH_TW_PDF"
        exit 1
    fi
}

# Build zh_tw cover PDF from translated LaTeX
build_zh_tw_cover_pdf() {
    print_info "Building zh_tw cover PDF: $ZH_TW_COVER_PDF"

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
        bash tools/copy-logo.sh $LOGO_FILE $ZH_TW_DIR
        bash tools/replace-fonts.sh $ZH_TW_COVER $ZH_TW_DIR/cover_page.tmp.tex 'Times New Roman' \"\$MAIN_FONT\" 'PingFang TC' \"\$CJK_FONT_TC\"
        bash tools/inject-date.sh $ZH_TW_DIR/cover_page.tmp.tex
        ( cd $ZH_TW_DIR && xelatex -interaction=nonstopmode -jobname=cover cover_page.tmp.tex )
        bash tools/cleanup-temp.sh $ZH_TW_DIR/cover_page.tmp.tex $ZH_TW_DIR/cover.aux $ZH_TW_DIR/cover.log
        echo 'Cleaned up intermediate translation files'
    "

    if [ -f "$WORK_DIR/$ZH_TW_COVER_PDF" ]; then
        print_info "Successfully generated zh_tw cover PDF: $ZH_TW_COVER_PDF"
    else
        print_error "Failed to generate $ZH_TW_COVER_PDF"
        exit 1
    fi
}

# Merge zh_tw cover + paper into printed PDF
build_zh_tw_printed() {
    print_info "Merging zh_tw cover + paper into: $ZH_TW_PRINTED_PDF"

    if [ ! -f "$WORK_DIR/$ZH_TW_COVER_PDF" ]; then
        build_zh_tw_cover_pdf
    fi

    if [ ! -f "$WORK_DIR/$ZH_TW_PDF" ]; then
        build_zh_tw_pdf
    fi

    run_in_docker "bash tools/merge-pdfs.sh $ZH_TW_COVER_PDF $ZH_TW_PDF $ZH_TW_PRINTED_PDF"

    if [ -f "$WORK_DIR/$ZH_TW_PRINTED_PDF" ]; then
        print_info "Successfully generated: $ZH_TW_PRINTED_PDF"
    else
        print_error "Failed to generate $ZH_TW_PRINTED_PDF"
        exit 1
    fi
}

# Build Traditional Chinese version (zh_tw)
build_zh_tw() {
    print_info "Building Traditional Chinese version: zh_tw"

    # Require API key file before running translation targets
    if [ ! -f "$API_KEY_FILE" ]; then
        print_error "API key file not found: $API_KEY_FILE"
        print_error "Create it with your Gemini API key before running zh_tw."
        echo "Example: echo \"<your-key>\" > .api_key && chmod 600 .api_key" >&2
        exit 1
    fi

    # Run full translation + build pipeline
    translate_zh_tw_markdown
    translate_zh_tw_cover
    build_zh_tw_pdf
    build_zh_tw_cover_pdf
    build_zh_tw_printed

    print_info "Translation to Traditional Chinese completed. PDFs generated in $ZH_TW_DIR/"
}

# Clean generated files
clean() {
    print_info "Cleaning generated files..."
    run_in_docker "bash tools/clean.sh paper.pdf $PDF $COVER_PDF $PRINTED_PDF $TEMP_SRC $COVER_TEMP_TEX"
    run_in_docker "rm -f thesis[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].pdf 2>/dev/null || true"
    run_in_docker "rm -f images/mermaid-*.png 2>/dev/null || true"
    run_in_docker "rm -f $MERMAID_TEMP_SRC 2>/dev/null || true"
    run_in_docker "rm -rf zh_tw 2>/dev/null || true"
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

# Install dependencies (informational only)
deps() {
    print_info "Note: This target is for local development."
    print_info "In Docker, all tools are pre-installed."
    print_info "If you want to install dependencies locally, run: bash tools/deps.sh"
}

# Show help
show_help() {
    cat <<EOF
Development Operations Center - devops.sh

Usage: ./devops.sh [target]

Available targets:
  help      - Show this help message [default]
  pdf       - Build the main paper PDF (paper.pdf)
  pdf_date  - Build the paper PDF with date suffix
  cover     - Build the cover page PDF
  printed   - Build the printed version (cover + paper)
  zh_tw     - Run the Traditional Chinese translation pipeline
  tags      - Generate .tags from all Markdown files
  clean     - Remove all generated files
  deps      - Show information about dependencies

Examples:
  ./devops.sh           # Show this help message
  ./devops.sh pdf       # Build paper.pdf
  ./devops.sh pdf_date  # Build thesisYYYYMMDD.pdf
  ./devops.sh cover     # Build only the cover page
  ./devops.sh clean     # Clean all generated files

Note: All builds run inside Docker container (pandocker-with-tools)
EOF
}

# Main script logic
main() {
    # Default target is 'help'
    TARGET="${1:-help}"

    # Handle help immediately without Docker checks
    case "$TARGET" in
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
    
    case "$TARGET" in
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
        zh_tw)
            build_zh_tw
            ;;
        tags)
            build_tags
            ;;
        clean)
            clean
            ;;
        deps)
            deps
            ;;
        *)
            print_error "Unknown target: $TARGET"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
