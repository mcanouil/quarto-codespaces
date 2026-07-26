#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

VERSION=${VERSION:-"latest"}

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

install_uv() {
  local version=$1
  local url
  if [ "${version}" = "latest" ]; then
    url="https://github.com/astral-sh/uv/releases/latest/download/uv-installer.sh"
  else
    url="https://github.com/astral-sh/uv/releases/download/${version}/uv-installer.sh"
  fi
  check_packages curl ca-certificates
  curl --proto '=https' --tlsv1.2 -LsSf "${url}" | env UV_INSTALL_DIR="/usr/local/bin" sh
}

enable_autocompletion() {
  # shellcheck disable=SC2016
  echo 'eval "$(uv generate-shell-completion zsh)"' >>/usr/share/zsh/vendor-completions/_uv
}

install_uv "${VERSION}"
enable_autocompletion
apt-get clean && rm -rf /var/lib/apt/lists/*
