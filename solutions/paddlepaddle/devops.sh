#!/usr/bin/env bash

# DevOps helper for PaddleOCR segment.py
# - Creates an isolated Python 3.11+ virtual environment
# - Installs required Python dependencies
# - "seg": run segment.py
# - "tell": run describe.py with repo .api_key
# - "croppings": run describe.py and export text-region crops

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VENV_DIR="${SCRIPT_DIR}/.venv"
API_KEY_FILE="${REPO_ROOT}/.api_key"
GEMINI_MODEL="${GEMINI_MODEL:-gemini-2.5-flash}"

PYTHON_BIN=""

print_info() {
  echo "[INFO] $*"
}

print_error() {
  echo "[ERROR] $*" >&2
}

detect_python() {
  # Prefer an explicit Python 3.11 binary when available
  for cmd in python3.11 python3 python; do
    if command -v "$cmd" >/dev/null 2>&1; then
      PYTHON_BIN="$cmd"
      return 0
    fi
  done

  print_error "Python 3.11+ is required but was not found in PATH."
  print_error "Install Python 3.11 and re-run this script."
  exit 1
}

ensure_venv() {
  if [ ! -d "$VENV_DIR" ]; then
    detect_python
    print_info "Creating virtual environment in $VENV_DIR using $PYTHON_BIN"
    "$PYTHON_BIN" -m venv "$VENV_DIR"
  fi
}

activate_venv() {
  # shellcheck disable=SC1091
  source "$VENV_DIR/bin/activate"
}

deps() {
  ensure_venv
  activate_venv

  print_info "Upgrading pip..."
  pip install --upgrade pip

  print_info "Installing PaddleOCR layout detection dependencies..."
  # Package set for segment.py and describe.py:
  # - paddlepaddle, paddleocr: OCR and layout detection
  # - opencv-python: image processing (cv2)
  # - numpy: array operations
  pip install \
    "paddlepaddle>=2.6.0" \
    "paddleocr>=2.7.0" \
    "opencv-python>=4.8.0" \
    "numpy>=1.24.0"

  print_info "Pre-downloading Traditional Chinese OCR model (chinese_cht)..."
  # Trigger download of chinese_cht language model so first run is faster.
  # Models are cached in ~/.paddlex/official_models/ after first download.
  if ! python -c 'from paddleocr import PaddleOCR; PaddleOCR(use_textline_orientation=False, lang="chinese_cht")'; then
    print_error "Failed to pre-download chinese_cht model. It will download on first use."
  fi

  print_info "Dependency installation complete."
}

seg_layout() {
  if [ $# -lt 1 ]; then
    print_error "Missing image path."
    echo "Usage: $0 seg <image_path> [--layout-threshold <float>]"
    exit 1
  fi

  local image_path="$1"
  shift || true

  if [ ! -f "$image_path" ]; then
    print_error "Image file not found: $image_path"
    exit 1
  fi

  # Optional args forwarded to segment.py
  local seg_args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --layout-threshold)
        if [ -z "${2:-}" ]; then
          print_error "Missing value for --layout-threshold"
          exit 1
        fi
        seg_args+=("--layout-threshold" "$2")
        shift 2
        ;;
      *)
        print_error "Unknown option for seg: $1"
        echo "Usage: $0 seg <image_path> [--layout-threshold <float>]"
        exit 1
        ;;
    esac
  done

  ensure_venv
  activate_venv

  print_info "Running segment.py on: $image_path"
  python "$SCRIPT_DIR/segment.py" "$image_path" "${seg_args[@]}"
}

tell_descriptions() {
  if [ $# -lt 2 ]; then
    print_error "Missing metadata JSON and/or image path."
    echo "Usage: $0 tell <metadata.json> <image_path> [output_dir] [--correct-ocr]"
    exit 1
  fi

  local metadata_json="$1"
  local image_path="$2"
  shift 2

  local output_dir="."
  local correct_ocr_flag=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --correct-ocr)
        correct_ocr_flag=("--correct-ocr")
        shift
        ;;
      *)
        output_dir="$1"
        shift
        ;;
    esac
  done

  if [ ! -f "$metadata_json" ]; then
    print_error "Metadata file not found: $metadata_json"
    exit 1
  fi
  if [ ! -f "$image_path" ]; then
    print_error "Image file not found: $image_path"
    exit 1
  fi

  ensure_venv
  activate_venv

  print_info "Running describe.py (API key: $API_KEY_FILE${correct_ocr_flag:+, OCR correction enabled})"
  python "$SCRIPT_DIR/describe.py" \
    --api-key-file "$API_KEY_FILE" \
    "${correct_ocr_flag[@]}" \
    "$metadata_json" "$image_path" "$output_dir"
}

croppings() {
  if [ $# -lt 2 ]; then
    print_error "Missing metadata JSON and/or image path."
    echo "Usage: $0 croppings <metadata.json> <image_path> [output_dir]"
    exit 1
  fi

  local metadata_json="$1"
  local image_path="$2"
  local output_dir="${3:-.}"

  if [ ! -f "$metadata_json" ]; then
    print_error "Metadata file not found: $metadata_json"
    exit 1
  fi
  if [ ! -f "$image_path" ]; then
    print_error "Image file not found: $image_path"
    exit 1
  fi

  ensure_venv
  activate_venv

  print_info "Running describe.py with text crop export (API key: $API_KEY_FILE, model: $GEMINI_MODEL)"
  python "$SCRIPT_DIR/describe.py" \
    --api-key-file "$API_KEY_FILE" \
    --model "$GEMINI_MODEL" \
    --export-text-crops-dir "croppings" \
    "$metadata_json" "$image_path" "$output_dir"
}

show_help() {
  cat <<'HELPEOF'
DevOps helper for PaddleOCR layout detection

Usage:
  ./devops.sh deps                                          # Create venv and install dependencies
  ./devops.sh seg <image_path> [--layout-threshold <float>]  # Run segment.py on an image
  ./devops.sh tell <metadata.json> <image_path> [output_dir] [--correct-ocr] # Run describe.py (uses repo .api_key)
  ./devops.sh croppings <metadata.json> <image_path> [output_dir] # Run describe.py and export text crops
  ./devops.sh help                                           # Show this help

Notes:
- This script manages a local virtual environment in ".venv" under this directory.
- segment.py currently targets Python 3.11 (PaddlePaddle does not yet support 3.14).
- tell uses the repository root .api_key for Gemini (image description).
HELPEOF
}

main() {
  local target="${1:-help}"
  shift || true

  case "$target" in
    deps)
      deps "$@"
      ;;
    seg)
      seg_layout "$@"
      ;;
    tell)
      tell_descriptions "$@"
      ;;
    croppings)
      croppings "$@"
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      print_error "Unknown target: $target"
      echo
      show_help
      exit 1
      ;;
  esac
}

main "$@"

