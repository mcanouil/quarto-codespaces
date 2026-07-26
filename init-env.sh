#!/usr/bin/env bash

set -euo pipefail

show_help() {
  echo "Usage: $0 [--what/-w all|r|python|julia] [--force/-f] [--help/-h]"
  echo "  --what/-w: Specify what to initialise (default: all)."
  echo "    all: Initialise R (renv), Python (uv), and Julia (project)."
  echo "    r: Initialise R (renv)."
  echo "    python: Initialise Python (uv)."
  echo "    julia: Initialise Julia (project)."
  echo "  --force/-f: Force initialisation regardless of existing files."
  echo "  --help/-h: Show this help message."
}

initialise_r() {
  local deps=$1
  deps=${deps//,/\",\"}
  if [ "${FORCE}" = true ] || [ ! -f "renv.lock" ]; then
    if [ -f ".Rprofile" ] && grep -q 'source("renv/activate.R")' .Rprofile; then
      sed -i.bak '/source("renv\/activate.R")/d' .Rprofile && rm -f .Rprofile.bak
    fi
    Rscript -e 'renv::init(bare = FALSE)'
    Rscript -e "renv::install(c('${deps}'))"
    Rscript -e 'renv::snapshot(type = "all")'
  fi
}

initialise_uv() {
  local deps=$1
  deps=${deps//,/ }
  if [ "${FORCE}" = true ] || [ ! -f "uv.lock" ]; then
    uv init --no-package --vcs none --bare --no-readme --author-from none
    uv venv
    # shellcheck disable=SC1091
    source .venv/bin/activate
    # shellcheck disable=SC2086
    uv add ${deps}
    uv sync
  fi
}

initialise_julia() {
  local deps=$1
  deps=${deps//,/\",\"}
  if [ "${FORCE}" = true ] || [ ! -f "Project.toml" ]; then
    julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'
    julia --project=. -e "using Pkg; Pkg.add([\"${deps}\"])"
  fi
}

WHAT="all"
FORCE=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --what | -w)
      WHAT="$2"
      shift
      ;;
    --force | -f)
      FORCE=true
      ;;
    --help | -h)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown parameter passed: $1"
      show_help
      exit 1
      ;;
  esac
  shift
done

case ${WHAT} in
  all)
    initialise_r "rmarkdown,languageserver"
    initialise_uv "jupyter,papermill"
    initialise_julia "IJulia"
    ;;
  r)
    initialise_r "rmarkdown,languageserver"
    ;;
  python)
    initialise_uv "jupyter,papermill"
    ;;
  julia)
    initialise_julia "IJulia"
    ;;
  *)
    echo "Unknown option for --what: ${WHAT}"
    show_help
    exit 1
    ;;
esac
