#!/bin/bash -e

APP_NAME="${APP_NAME:-clamav}"
IMAGE_VERSION="${IMAGE_VERSION:-latest}"

# Registries to push to (space-separated)
# Default: ghcr.io and docker.io
REGISTRIES="${REGISTRIES:-ghcr.io/jloehel docker.io/jloehel}"

# Whether to also push :latest tag
PUSH_LATEST="${PUSH_LATEST:-false}"

# Sanitize IMAGE_VERSION
SAFE_IMAGE_VERSION=$(echo "$IMAGE_VERSION" | tr -sc '[:alnum:].\n\r' '-' | tr '[:upper:]' '[:lower:]' | cut -c 1-127)

# Source tag from build
BUILD_TAG="${APP_NAME}:${SAFE_IMAGE_VERSION}"

# Parse OS_FLAVOR from IMAGE_VERSION if it matches tag format
# Tag format: <os_flavor>-<os_version>-<app_version>-<unofficial_sigs_version>
PART_COUNT=$(echo "$IMAGE_VERSION" | tr -cd '-' | wc -c)
if [ "$PART_COUNT" -eq 3 ]; then
    OS_FLAVOR="$(echo "$IMAGE_VERSION" | cut -d"-" -f1)"
    APP_VERSION="$(echo "$IMAGE_VERSION" | cut -d"-" -f3)"
else
    OS_FLAVOR="${OS_FLAVOR:-alpine}"
    APP_VERSION=""
fi

echo "========================================"
echo "Pushing Docker Image"
echo "========================================"
echo "BUILD_TAG: ${BUILD_TAG}"
echo "OS_FLAVOR: ${OS_FLAVOR}"
echo "REGISTRIES: ${REGISTRIES}"
echo "PUSH_LATEST: ${PUSH_LATEST}"
echo "========================================"

for REGISTRY in ${REGISTRIES}; do
    # Push with full version tag (e.g., alpine-3.23-1.4.3-7.2.5)
    FULL_TAG="${REGISTRY}/${APP_NAME}:${SAFE_IMAGE_VERSION}"
    echo "Tagging and pushing: ${FULL_TAG}"
    docker tag "${BUILD_TAG}" "${FULL_TAG}"
    docker push "${FULL_TAG}"

    # Push OS-specific latest tag (e.g., alpine-latest)
    OS_LATEST_TAG="${REGISTRY}/${APP_NAME}:${OS_FLAVOR}-latest"
    echo "Tagging and pushing: ${OS_LATEST_TAG}"
    docker tag "${BUILD_TAG}" "${OS_LATEST_TAG}"
    docker push "${OS_LATEST_TAG}"

    # Push app version tag (e.g., 1.4.3-alpine)
    if [ -n "$APP_VERSION" ]; then
        VERSION_TAG="${REGISTRY}/${APP_NAME}:${APP_VERSION}-${OS_FLAVOR}"
        echo "Tagging and pushing: ${VERSION_TAG}"
        docker tag "${BUILD_TAG}" "${VERSION_TAG}"
        docker push "${VERSION_TAG}"
    fi

    # Push global :latest tag only for alpine and if PUSH_LATEST is true
    if [ "${PUSH_LATEST}" = "true" ] && [ "${OS_FLAVOR}" = "alpine" ]; then
        LATEST_TAG="${REGISTRY}/${APP_NAME}:latest"
        echo "Tagging and pushing: ${LATEST_TAG}"
        docker tag "${BUILD_TAG}" "${LATEST_TAG}"
        docker push "${LATEST_TAG}"
    fi
done

echo "========================================"
echo "Push complete"
echo "========================================"
