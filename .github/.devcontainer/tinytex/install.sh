#!/usr/bin/env bash

set -e

export DEBIAN_FRONTEND=noninteractive

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}

if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

architecture="$(dpkg --print-architecture)"
if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "arm64" ]; then
  echo "(!) Architecture ${architecture} unsupported"
  exit 2
fi

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
  USERNAME=""
  POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
  for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
    if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
      USERNAME=${CURRENT_USER}
      break
    fi
  done
  if [ "${USERNAME}" = "" ]; then
    USERNAME=root
  fi
elif [ "${USERNAME}" = "none" ] || ! id -u "${USERNAME}" >/dev/null 2>&1; then
  USERNAME=root
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

install_tinytex() {
  echo "Installing TinyTeX..."
  check_packages libfontconfig
  # su "${USERNAME}" -c 'quarto install tinytex --quiet'
  check_packages curl ca-certificates
  curl -sL "https://yihui.org/tinytex/install-bin-unix.sh" | sh -s - --admin --no-path
  TINYTEX_OPT="/opt/tinytex"
  mv /root/.TinyTeX "${TINYTEX_OPT}"
  TINYTEX_INSTALL_DIR="${TINYTEX_OPT}/bin/$(uname -m)-linux"
  "${TINYTEX_INSTALL_DIR}/tlmgr" option sys_bin /usr/local/bin
  "${TINYTEX_INSTALL_DIR}/tlmgr" path add
  echo "TinyTeX installation complete."

  # Create tinytex group and add users to it
  groupadd -f tinytex
  usermod -a -G tinytex root
  if [ "${USERNAME}" != "root" ]; then
    usermod -a -G tinytex "${USERNAME}"
  fi
  # Set group ownership and permissions
  chgrp -R tinytex "${TINYTEX_OPT}"
  chmod -R 775 "${TINYTEX_OPT}"

  # Set environment variables system-wide for TinyTeX
  echo "export TEXLIVE_USE_USERMODE=1" > /etc/profile.d/tinytex.sh
  chmod 644 /etc/profile.d/tinytex.sh

  # Initialise user tree for tlmgr in the non-root user's home directory
  su "${USERNAME}" -c "tlmgr init-usertree"
}

install_tinytex

apt-get clean && rm -rf /var/lib/apt/lists/*

echo "Done!"
