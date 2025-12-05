#!/bin/bash
# Docker wrapper for make - runs make inside dalibo/pandocker container
#
# This script uses a derived image with jq and curl pre-installed to avoid
# installing them on every translation run. The container is automatically removed
# after the build completes. All toolchains (pandoc, xelatex, make, etc.)
# are available inside the container.

set -e

# Base image name and tag
BASE_IMAGE_NAME="dalibo/pandocker"
BASE_IMAGE_TAG="latest-full"
BASE_IMAGE="${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"

# Derived image name (with jq and curl pre-installed)
DERIVED_IMAGE_NAME="pandocker-with-tools"
DERIVED_IMAGE_TAG="latest"
DERIVED_IMAGE="${DERIVED_IMAGE_NAME}:${DERIVED_IMAGE_TAG}"

# Check if base image exists, pull if needed
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${BASE_IMAGE}$"; then
    echo "Base image ${BASE_IMAGE} not found locally. Pulling..."
    docker pull "$BASE_IMAGE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to pull ${BASE_IMAGE}" >&2
        echo "Please check your Docker connection and try again." >&2
        exit 1
    fi
fi

# Get the absolute path of the current directory
WORK_DIR=$(pwd)

# Check if derived image exists, build if needed
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${DERIVED_IMAGE}$"; then
    echo "Derived image ${DERIVED_IMAGE} not found. Building from Dockerfile..."
    if [ ! -f "$WORK_DIR/Dockerfile" ]; then
        echo "Error: Dockerfile not found in $WORK_DIR" >&2
        echo "Please create a Dockerfile that extends ${BASE_IMAGE} and installs jq and curl." >&2
        exit 1
    fi
    docker build -t "$DERIVED_IMAGE" -f "$WORK_DIR/Dockerfile" "$WORK_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build derived image ${DERIVED_IMAGE}" >&2
        exit 1
    fi
    echo "Derived image built successfully."
fi

# Use the derived image
IMAGE="$DERIVED_IMAGE"

API_KEY_FILE="$WORK_DIR/.api_key"

# Require API key file before running translation targets
if [ ! -f "$API_KEY_FILE" ]; then
    echo "Error: API key file not found: $API_KEY_FILE" >&2
    echo "Create it with your Gemini API key before running translation targets." >&2
    echo "Example: echo \"<your-key>\" > \"$API_KEY_FILE\" && chmod 600 \"$API_KEY_FILE\"" >&2
    # Only fail if a translation target is requested
    case " $* " in
        *" zh_tw "*|*"$(ZH_TW_DIR)"*|*"translate"* )
            exit 1;;
        * ) ;;
    esac
fi

# Run make inside the container
# --rm: automatically remove container after execution
# --entrypoint="": override container entrypoint to run make directly
# -u: preserve file ownership (use current user's UID/GID)
# -v: mount current directory as /workspace in container
# -w: set working directory in container
docker run --rm \
    --entrypoint="" \
    -u "$(id -u):$(id -g)" \
    -v "$WORK_DIR":/workspace \
    -w /workspace \
    "$IMAGE" \
    /usr/bin/make "$@"

