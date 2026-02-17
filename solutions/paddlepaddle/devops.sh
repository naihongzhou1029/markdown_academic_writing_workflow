#!/usr/bin/env bash

# DevOps helper for PaddleOCR segment.py
# - Creates an isolated Python 3.11+ virtual environment
# - Installs required Python dependencies
# - Provides a simple "run" target to execute segment.py

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/.venv"

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
  # Package set derived from imports in segment.py
  pip install \
    "paddlepaddle>=2.6.0" \
    "paddleocr>=2.7.0" \
    "opencv-python>=4.8.0" \
    "numpy>=1.24.0"

  print_info "Dependency installation complete."
}

run_layout() {
  if [ $# -lt 1 ]; then
    print_error "Missing image path."
    echo "Usage: $0 run <image_path> [--layout-threshold <float>]"
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
        print_error "Unknown option for run: $1"
        echo "Usage: $0 run <image_path> [--layout-threshold <float>]"
        exit 1
        ;;
    esac
  done

  ensure_venv
  activate_venv

  print_info "Running segment.py on: $image_path"
  python "$SCRIPT_DIR/segment.py" "$image_path" "${seg_args[@]}"
}

show_help() {
  cat <<EOF
DevOps helper for PaddleOCR layout detection

Usage:
  ./devops.sh deps                                   # Create venv and install dependencies
  ./devops.sh run <image_path> [--layout-threshold]  # Run segment.py on an image
  ./devops.sh help                                   # Show this help

Notes:
- This script manages a local virtual environment in ".venv" under this directory.
- segment.py currently targets Python 3.11 (PaddlePaddle does not yet support 3.14).
EOF
}

main() {
  local target="${1:-help}"
  shift || true

  case "$target" in
    deps)
      deps "$@"
      ;;
    run)
      run_layout "$@"
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

