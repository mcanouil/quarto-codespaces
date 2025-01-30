#!/usr/bin/env bash

show_help() {
  echo "Usage: $0 [--what/-w all|r|python|julia] [--force/-f] [--help/-h]"
  echo "  --what/-w: Specify what to initialise (default: all)."
  echo "    all: Initialise R (renv), Python (virtualenv), and Julia (project)."
  echo "    r: Initialise R (renv)."
  echo "    python: Initialise Python (virtualenv)."
  echo "    julia: Initialise Julia (project)."
  echo "  --force/-f: Force initialisation regardless of existing files."
  echo "  --help/-h: Show this help message."
}

initialise_r() {
  if [ "$FORCE" = true ] || [ ! -f "renv.lock" ]; then
    Rscript -e 'renv::init(bare = FALSE)'
    Rscript -e 'renv::install("rmarkdown")'
    Rscript -e 'renv::snapshot(type = "all")'
  fi
}

initialise_python() {
  if [ "$FORCE" = true ] || [ ! -f "requirements.txt" ]; then
    python3 -m venv .venv
    source .venv/bin/activate
    python3 -m pip install jupyter papermill
    python3 -m pip freeze > requirements.txt
  fi
}

initialise_julia() {
  if [ "$FORCE" = true ] || [ ! -f "Project.toml" ]; then
    julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'
    julia --project=. -e 'using Pkg; Pkg.add("IJulia")'
  fi
}

WHAT="all"
FORCE=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --what|-w)
      WHAT="$2"
      shift
      ;;
    --force|-f)
      FORCE=true
      ;;
    --help|-h)
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

case $WHAT in
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
  *)
    echo "Unknown option for --what: $WHAT"
    show_help
    exit 1
    ;;
esac
