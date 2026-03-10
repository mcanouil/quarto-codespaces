#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}

PLATFORMS=${INSTALLONPLATFORMS:-"amd64,arm64"}

R_DEPS=${RDEPS:-"rmarkdown"}

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

quarto_r_deps() {
  local deps=$1
  deps=${deps//,/\",\"}
  su "${USERNAME}" -c "Rscript -e 'pak::pkg_install(c(\"${deps}\"))'"
}

if [[ ",${PLATFORMS}," == *",${architecture},"* ]]; then
  quarto_r_deps "${R_DEPS}"
else
  echo "(!) Skipping R dependencies for ${architecture} architecture"
fi

apt-get clean && rm -rf /var/lib/apt/lists/*

echo "Done!"
