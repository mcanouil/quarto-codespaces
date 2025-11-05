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

# Define relative cache/temp paths to clean
user_cache_paths=(
  ".cache"
  ".local/share/Trash"
  "tmp"
  ".npm"
  ".node-gyp"
  ".config/yarn"
  ".yarn"
  ".julia/logs"
  ".julia/compiled"
  ".R"
)

# Build list of users to clean
users_to_clean=("${USER_HOME}")
if [ "${USERNAME}" != "root" ]; then
  users_to_clean+=("/root")
fi

# Clean user-specific cache directories
for user_home in "${users_to_clean[@]}"; do
  for cache_path in "${user_cache_paths[@]}"; do
    full_path="${user_home}/${cache_path}"
    if [ -e "${full_path}" ]; then
      echo "[cleanup] Removing: ${full_path}"
      rm -rf "${full_path}" || true
    else
      echo "[cleanup] Not found: ${full_path}"
    fi
  done
done

# Clean system-wide paths
# system_paths=(
#   "/opt/tinytex/.TinyTeX/tlpkg/texlive.tlpdb.main.*"
# )

# for path in "${system_paths[@]}"; do
#   if [ -e "${path}" ]; then
#     echo "[cleanup] Removing: ${path}"
#     rm -rf ${path} || true
#   else
#     echo "[cleanup] Not found: ${path}"
#   fi
# done

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

if command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
  echo "[cleanup] Cleaning pip cache"
  python3 -m pip cache purge 2>/dev/null || true
  for user_home in "${users_to_clean[@]}"; do
    rm -rf "${user_home}/.cache/pip" || true
  done
fi

if command -v uv >/dev/null 2>&1; then
  echo "[cleanup] Cleaning uv cache"
  uv cache clean 2>/dev/null || true
  for user_home in "${users_to_clean[@]}"; do
    rm -rf "${user_home}/.cache/uv" || true
  done
fi

if command -v npm >/dev/null 2>&1; then
  echo "[cleanup] Cleaning npm cache"
  npm cache clean --force 2>/dev/null || true
fi

echo "[cleanup] Done."
