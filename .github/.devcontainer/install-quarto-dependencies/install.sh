#!/usr/bin/env bash

set -e

export DEBIAN_FRONTEND=noninteractive
USERNAME=${_REMOTE_USER:-"vscode"}
DEPENDENCIES=${DEPENDENCIES:-"all"}

quarto_r_deps() {
  su "${USERNAME}" -c "Rscript -e 'pak::pkg_install(\"rmarkdown\")'"
}

quarto_python_deps() {
  su "${USERNAME}" -c "python3 -m pip install jupyter"
}

quarto_julia_deps() {
  su "${USERNAME}" -c "julia -e 'using Pkg; Pkg.add("IJulia")'"
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
