#!/usr/bin/env bash

set -e

export DEBIAN_FRONTEND=noninteractive

DEPENDENCIES=${DEPENDENCIES:-"all"}

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
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
  su "${USERNAME}" -c "Rscript -e 'pak::pkg_install(\"rmarkdown\")'"
}

quarto_python_deps() {
  python3 -m pip install jupyter papermill
}

quarto_julia_deps() {
  su "${USERNAME}" -c "~/.juliaup/bin/julia -e 'using Pkg; Pkg.add(\"IJulia\")'"
}

case ${DEPENDENCIES} in
  all)
    quarto_r_deps
    quarto_python_deps
    quarto_julia_deps
    ;;
  r)
    quarto_r_deps
    ;;
  python)
    quarto_python_deps
    ;;
  julia)
    quarto_julia_deps
    ;;
esac
