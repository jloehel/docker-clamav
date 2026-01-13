#!/bin/sh

# The script will install all necessary dependencies for this image.

set -eux

base_dependencies=""
if [ -f /build/dependencies/base ]; then
    base_dependencies=$(xargs < /build/dependencies/base)
fi

os_dependencies=""
if [ -f "/build/dependencies/${OS_FLAVOR}" ]; then
    os_dependencies=$(xargs < "/build/dependencies/${OS_FLAVOR}")
fi

dependencies="${os_dependencies} ${base_dependencies}"
echo "Dependencies: ${dependencies}"

package_manager_install=""

if [ "${OS_FLAVOR}" = "alpine" ]; then
    package_manager_install="apk add --no-cache"
fi

if [ "${OS_FLAVOR}" = "opensuse/leap" ] || [ "${OS_FLAVOR}" = "opensuse/tumbleweed" ]; then
    package_manager_install="zypper -n in"
fi

if [ "${OS_FLAVOR}" = "fedora" ]; then
    package_manager_install="dnf -y install"
fi

if [ "${OS_FLAVOR}" = "debian" ] || [ "${OS_FLAVOR}" = "ubuntu" ]; then
    export DEBIAN_FRONTEND=noninteractive
    package_manager_install="apt-get install -y"
fi

if [ -n "${dependencies}" ] && [ -n "${package_manager_install}" ]; then
    # shellcheck disable=SC2086
    ${package_manager_install} ${dependencies}
fi
