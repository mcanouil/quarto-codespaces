#!/usr/bin/env bash

set -euo pipefail

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}

# Resolve username
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
  USERNAME=""
  POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F":" '$3==val{print $1}' /etc/passwd)")
  for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
    if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
      USERNAME=${CURRENT_USER}
      break
    fi
  done
  if [ "${USERNAME}" = "" ]; then
    USERNAME=root
  fi
elif ! id -u "${USERNAME}" >/dev/null 2>&1; then
  USERNAME=root
fi

echo "[cleanup] Running cleanup feature as user: ${USERNAME}"

# Determine home directory for the target user
if [ "${USERNAME}" = "root" ]; then
  USER_HOME="/root"
else
  USER_HOME=$(eval echo "~${USERNAME}")
fi

echo "[cleanup] Target home: ${USER_HOME}"

cleanup_paths=(
  "${USER_HOME}/.cache"
  "${USER_HOME}/.local/share/Trash"
  "${USER_HOME}/tmp"
  "${USER_HOME}/.npm/_cacache"
)

for path in "${cleanup_paths[@]}"; do
  if [ -e "${path}" ]; then
    echo "[cleanup] Removing: ${path}"
    rm -rf "${path}" || true
  else
    echo "[cleanup] Not found: ${path}"
  fi
done

echo "[cleanup] Cleaning system temporary files"
if [ -d "/tmp" ]; then
  echo "[cleanup] Removing: /tmp/*"
  rm -rf /tmp/* || true
fi

echo "[cleanup] Cleaning package manager caches"
if command -v apt-get >/dev/null 2>&1; then
  echo "[cleanup] Running: apt-get clean"
  apt-get clean || true

  if [ -d "/var/lib/apt/lists" ]; then
    echo "[cleanup] Removing: /var/lib/apt/lists/*"
    rm -rf /var/lib/apt/lists/* || true
  fi
fi

echo "[cleanup] Done."
