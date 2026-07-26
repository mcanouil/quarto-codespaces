#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

VERSION=${VERSION:-"22"}

if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

apt_get_update() {
  if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
    echo "Running apt-get update..."
    apt-get update -y
  fi
}

# Checks if packages are installed and installs them if not
check_packages() {
  if ! dpkg -s "$@" >/dev/null 2>&1; then
    apt_get_update
    apt-get -y install --no-install-recommends "$@"
  fi
}

install_decktape() {
  local version=$1
  local url="https://deb.nodesource.com/setup_${version}.x"
  check_packages curl ca-certificates
  curl --proto '=https' --tlsv1.2 -LsSf "${url}" | bash -
  check_packages nodejs
  npm install -g decktape
}

install_decktape "${VERSION}"

apt-get clean && rm -rf /var/lib/apt/lists/*

echo "Done!"
