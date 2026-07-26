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

# Google only ships amd64 debs; arm64 gets Chromium via Playwright's builds.
# Both arches expose the browser as /usr/local/bin/chromium (see containerEnv).
install_chrome_amd64() {
  check_packages curl gnupg
  curl --proto '=https' --tlsv1.2 -fSsL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google-chrome.gpg >>/dev/null
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list
  apt_get_update
  check_packages google-chrome-stable
  ln -sf /usr/bin/google-chrome-stable /usr/local/bin/chromium
}

install_chromium_arm64() {
  check_packages curl ca-certificates
  # The decktape feature installs Node.js first; fall back to the distribution
  # packages so this feature also works on its own.
  if ! command -v npx >/dev/null 2>&1; then
    check_packages nodejs npm
  fi
  export PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
  npx --yes playwright install --with-deps chromium
  local chrome_bin
  chrome_bin=$(find "${PLAYWRIGHT_BROWSERS_PATH}" -type f -name chrome -path '*chrome-linux*' | head -n 1)
  if [ -z "${chrome_bin}" ]; then
    echo "(!) Chromium binary not found under ${PLAYWRIGHT_BROWSERS_PATH}"
    exit 3
  fi
  chmod -R a+rX "${PLAYWRIGHT_BROWSERS_PATH}"
  ln -sf "${chrome_bin}" /usr/local/bin/chromium
}

if [ "${arch}" = "amd64" ]; then
  install_chrome_amd64
else
  install_chromium_arm64
fi

apt-get clean && rm -rf /var/lib/apt/lists/*

echo "Done!"
