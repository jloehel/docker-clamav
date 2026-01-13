#!/bin/bash -e

# Default values
ARCH="${ARCH:-amd64}"
OS="${OS:-linux}"

IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION:-ClamAV with unofficial signatures}"
APP_NAME="${APP_NAME:-clamav}"
APP_NAME_UPPER="$(echo "$APP_NAME" | tr 'a-z\-\ ' 'A-Z__')"
APP_USERNAME="${APP_USERNAME:-clamav}"

# Version handling
# Tag format: <os_flavor>-<os_version>-<app_version>-<unofficial_sigs_version>
# Example: alpine-3.23-1.4.3-7.2.5
if [ -z "${CI_BUILD+x}" ]; then
    # Local build - use defaults or environment variables
    IMAGE_VERSION="${IMAGE_VERSION:-latest}"
    OS_FLAVOR="${OS_FLAVOR:-alpine}"
    OS_VERSION="${OS_VERSION:-3.23}"
    APP_VERSION="${APP_VERSION:-1.4.3}"
    UNOFFICIAL_SIGS_VERSION="${UNOFFICIAL_SIGS_VERSION:-7.2.5}"
else
    # CI build - parse version from IMAGE_VERSION if not already set
    # Only parse if IMAGE_VERSION matches the tag format (4 parts)
    PART_COUNT=$(echo "$IMAGE_VERSION" | tr -cd '-' | wc -c)
    if [ "$PART_COUNT" -eq 3 ] && [ -z "${OS_FLAVOR+x}" ]; then
        OS_FLAVOR="$(echo "$IMAGE_VERSION" | cut -d"-" -f1)"
        OS_VERSION="$(echo "$IMAGE_VERSION" | cut -d"-" -f2)"
        APP_VERSION="$(echo "$IMAGE_VERSION" | cut -d"-" -f3)"
        UNOFFICIAL_SIGS_VERSION="$(echo "$IMAGE_VERSION" | cut -d"-" -f4)"
    else
        # Use environment variables or defaults
        OS_FLAVOR="${OS_FLAVOR:-alpine}"
        OS_VERSION="${OS_VERSION:-3.23}"
        APP_VERSION="${APP_VERSION:-1.4.3}"
        UNOFFICIAL_SIGS_VERSION="${UNOFFICIAL_SIGS_VERSION:-7.2.5}"
    fi
fi

# Sanitize IMAGE_VERSION for tagging
SAFE_IMAGE_VERSION=$(echo "$IMAGE_VERSION" | tr -sc '[:alnum:].\n\r' '-' | tr '[:upper:]' '[:lower:]' | cut -c 1-127)

# Build tag - local tag without registry prefix
BUILD_TAG="${APP_NAME}:${SAFE_IMAGE_VERSION}"

echo "========================================"
echo "Building Docker Image"
echo "========================================"
echo "ARCH: ${ARCH}"
echo "OS: ${OS}"
echo "OS_FLAVOR: ${OS_FLAVOR}"
echo "OS_VERSION: ${OS_VERSION}"
echo "APP_NAME: ${APP_NAME}"
echo "APP_VERSION: ${APP_VERSION}"
echo "UNOFFICIAL_SIGS_VERSION: ${UNOFFICIAL_SIGS_VERSION}"
echo "IMAGE_VERSION: ${SAFE_IMAGE_VERSION}"
echo "BUILD_TAG: ${BUILD_TAG}"
echo "========================================"

docker build \
    --build-arg ARCH="${ARCH}" \
    --build-arg OS="${OS}" \
    --build-arg OS_FLAVOR="${OS_FLAVOR}" \
    --build-arg OS_VERSION="${OS_VERSION}" \
    --build-arg IMAGE_VERSION="${SAFE_IMAGE_VERSION}" \
    --build-arg IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION}" \
    --build-arg APP_NAME="${APP_NAME}" \
    --build-arg APP_NAME_UPPER="${APP_NAME_UPPER}" \
    --build-arg APP_VERSION="${APP_VERSION}" \
    --build-arg UNOFFICIAL_SIGS_VERSION="${UNOFFICIAL_SIGS_VERSION}" \
    --build-arg APP_USERNAME="${APP_USERNAME}" \
    -t "${BUILD_TAG}" \
    -f Dockerfile .

echo "========================================"
echo "Build complete: ${BUILD_TAG}"
echo "========================================"
