#!/bin/bash -e

export ARCH=amd64
export OS=linux
export OS_FLAVOR=alpine
export OS_VERSION=3.23
export IMAGE_VERSION=latest-alpine
export IMAGE_DESCRIPTION="nightly ClamAV build"
export APP_NAME=clamav
export APP_VERSION=1.4.3-r2
export APP_USERNAME=clamav
export UNOFFICIAL_SIGS_VERSION=7.2.5

./docker_build.sh
