#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

arch="$(dpkg --print-architecture)"
if [ "${arch}" != "amd64" ] && [ "${arch}" != "arm64" ]; then
  echo "Architecture ${arch} unsupported"
  exit 2
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

install_chrome() {
  local arch="$1"
  check_packages curl gnupg
  curl --proto '=https' --tlsv1.2 -fSsL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google-chrome.gpg >>/dev/null
  echo "deb [arch=${arch} signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list
  apt_get_update
  check_packages google-chrome-stable
}

install_chrome "${arch}"

apt-get clean && rm -rf /var/lib/apt/lists/*

echo "Done!"
