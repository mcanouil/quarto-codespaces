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

initialise_julia() {
  su "${USERNAME}" -c "julia -e 'using Pkg; Pkg.add("IJulia")'"
}

case ${DEPENDENCIES} in
  all)
    initialise_r
    initialise_python
    initialise_julia
    ;;
  r)
    initialise_r
    ;;
  python)
    initialise_python
    ;;
  julia)
    initialise_julia
    ;;
esac
