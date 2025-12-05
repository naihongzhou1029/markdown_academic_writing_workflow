#!/bin/bash
# Docker wrapper for make - runs make inside dalibo/pandocker container
#
# This script creates an ephemeral container that is automatically removed
# after the build completes. All toolchains (pandoc, xelatex, make, etc.)
# are available inside the container.

set -e

# Image name and tag
IMAGE_NAME="dalibo/pandocker"
IMAGE_TAG="latest-full"
IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

# Check if the image exists locally
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE}$"; then
    echo "Checking for alternative ${IMAGE_NAME} images..."
    AVAILABLE_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^${IMAGE_NAME}:" || true)
    
    if [ -n "$AVAILABLE_IMAGES" ]; then
        echo ""
        echo "Warning: Image ${IMAGE} not found locally."
        echo "Available ${IMAGE_NAME} images:"
        echo "$AVAILABLE_IMAGES" | sed 's/^/  /'
        echo ""
        echo "Pulling ${IMAGE}..."
        docker pull "$IMAGE"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to pull ${IMAGE}" >&2
            echo "Please check your Docker connection and try again." >&2
            exit 1
        fi
    else
        echo ""
        echo "Image ${IMAGE} not found locally. Pulling..."
        docker pull "$IMAGE"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to pull ${IMAGE}" >&2
            echo "Please check your Docker connection and try again." >&2
            exit 1
        fi
    fi
fi

# Get the absolute path of the current directory
WORK_DIR=$(pwd)
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

# Run make inside the dalibo/pandocker container
# --rm: automatically remove container after execution
# --entrypoint="": override container entrypoint to run make directly
# -u: preserve file ownership (use current user's UID/GID)
# -v: mount current directory as /workspace in container
# -w: set working directory in container
# Install curl and jq if missing (required for translation scripts)
docker run --rm \
    --entrypoint="" \
    -u "$(id -u):$(id -g)" \
    -v "$WORK_DIR":/workspace \
    -w /workspace \
    "$IMAGE" \
    bash -c "apt-get update -qq >/dev/null 2>&1 && (command -v curl >/dev/null 2>&1 || apt-get install -y -qq curl >/dev/null 2>&1) && (command -v jq >/dev/null 2>&1 || apt-get install -y -qq jq >/dev/null 2>&1) && /usr/bin/make \"\$@\"" \
    -- "$@"

