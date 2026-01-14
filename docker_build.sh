#!/bin/bash -e

# Default values
ARCH="${ARCH:-amd64}"
OS="${OS:-linux}"

IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION:-ClamAV with fangfrisch unofficial signatures}"
APP_NAME="${APP_NAME:-clamav}"
APP_NAME_UPPER="$(echo "$APP_NAME" | tr 'a-z\-\ ' 'A-Z__')"
APP_USERNAME="${APP_USERNAME:-clamav}"

# Version handling
# Tag format: <os_flavor>/<os_version>/<app_version>/<fangfrisch_version>/<build>
# Example: alpine/3.23/1.4.3/1.9.2/1
if [ -z "${CI_BUILD+x}" ]; then
    # Local build - use defaults or environment variables
    IMAGE_VERSION="${IMAGE_VERSION:-latest}"
    OS_FLAVOR="${OS_FLAVOR:-alpine}"
    OS_VERSION="${OS_VERSION:-3.23}"
    APP_VERSION="${APP_VERSION:-1.4.3}"
    FANGFRISCH_VERSION="${FANGFRISCH_VERSION:-1.9.2}"
    BUILD_NUMBER="${BUILD_NUMBER:-1}"
else
    # CI build - parse version from IMAGE_VERSION if not already set
    # Count slashes to detect tag format (should be 4 slashes = 5 parts)
    SLASH_COUNT=$(echo "$IMAGE_VERSION" | tr -cd '/' | wc -c)
    if [ "$SLASH_COUNT" -eq 4 ] && [ -z "${OS_FLAVOR+x}" ]; then
        OS_FLAVOR="$(echo "$IMAGE_VERSION" | cut -d'/' -f1)"
        OS_VERSION="$(echo "$IMAGE_VERSION" | cut -d'/' -f2)"
        APP_VERSION="$(echo "$IMAGE_VERSION" | cut -d'/' -f3)"
        FANGFRISCH_VERSION="$(echo "$IMAGE_VERSION" | cut -d'/' -f4)"
        BUILD_NUMBER="$(echo "$IMAGE_VERSION" | cut -d'/' -f5)"
    else
        # Use environment variables or defaults
        OS_FLAVOR="${OS_FLAVOR:-alpine}"
        OS_VERSION="${OS_VERSION:-3.23}"
        APP_VERSION="${APP_VERSION:-1.4.3}"
        FANGFRISCH_VERSION="${FANGFRISCH_VERSION:-1.9.2}"
        BUILD_NUMBER="${BUILD_NUMBER:-1}"
    fi
fi

# Docker tag format: replace / with - for valid docker tag
# alpine/3.23/1.4.3/1.9.2/1 -> alpine-3.23-1.4.3-1.9.2-1
DOCKER_TAG=$(echo "$IMAGE_VERSION" | tr '/' '-')
DOCKER_TAG=$(echo "$DOCKER_TAG" | tr -sc '[:alnum:].\n\r' '-' | tr '[:upper:]' '[:lower:]' | cut -c 1-127)

# Build tag - local tag without registry prefix
BUILD_TAG="${APP_NAME}:${DOCKER_TAG}"

echo "========================================"
echo "Building Docker Image"
echo "========================================"
echo "ARCH: ${ARCH}"
echo "OS: ${OS}"
echo "OS_FLAVOR: ${OS_FLAVOR}"
echo "OS_VERSION: ${OS_VERSION}"
echo "APP_NAME: ${APP_NAME}"
echo "APP_VERSION: ${APP_VERSION}"
echo "FANGFRISCH_VERSION: ${FANGFRISCH_VERSION}"
echo "BUILD_NUMBER: ${BUILD_NUMBER}"
echo "IMAGE_VERSION: ${IMAGE_VERSION}"
echo "DOCKER_TAG: ${DOCKER_TAG}"
echo "BUILD_TAG: ${BUILD_TAG}"
echo "========================================"

docker build \
    --build-arg ARCH="${ARCH}" \
    --build-arg OS="${OS}" \
    --build-arg OS_FLAVOR="${OS_FLAVOR}" \
    --build-arg OS_VERSION="${OS_VERSION}" \
    --build-arg IMAGE_VERSION="${IMAGE_VERSION}" \
    --build-arg IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION}" \
    --build-arg APP_NAME="${APP_NAME}" \
    --build-arg APP_NAME_UPPER="${APP_NAME_UPPER}" \
    --build-arg APP_VERSION="${APP_VERSION}" \
    --build-arg FANGFRISCH_VERSION="${FANGFRISCH_VERSION}" \
    --build-arg APP_USERNAME="${APP_USERNAME}" \
    -t "${BUILD_TAG}" \
    -f Dockerfile .

echo "========================================"
echo "Build complete: ${BUILD_TAG}"
echo "========================================"
