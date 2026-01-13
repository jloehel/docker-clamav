#!/bin/bash -e

export CI_BUILD=true
export APP_NAME=clamav
export APP_USERNAME=clamav
export REGISTRIES="ghcr.io/jloehel docker.io/jloehel"
export PUSH_LATEST=true

echo "========================================"
echo "Weekly Build"
echo "========================================"

# Get latest tags per OS flavor
ALPINE_TAG=$(git tag -l 'alpine-*' --sort=-v:refname | head -1)
UBUNTU_TAG=$(git tag -l 'ubuntu-*' --sort=-v:refname | head -1)

# Build Alpine if tag exists
if [ -n "$ALPINE_TAG" ]; then
    echo "Building Alpine: ${ALPINE_TAG}"
    export IMAGE_VERSION="${ALPINE_TAG}"
    export IMAGE_DESCRIPTION="ClamAV ${ALPINE_TAG} weekly rebuild"
    ./docker_build.sh
    ./docker_push.sh
fi

# Build Ubuntu if tag exists
if [ -n "$UBUNTU_TAG" ]; then
    echo "Building Ubuntu: ${UBUNTU_TAG}"
    export IMAGE_VERSION="${UBUNTU_TAG}"
    export IMAGE_DESCRIPTION="ClamAV ${UBUNTU_TAG} weekly rebuild"
    ./docker_build.sh
    ./docker_push.sh
fi

echo "========================================"
echo "Weekly Build complete"
echo "========================================"
