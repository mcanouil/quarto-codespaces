#!/usr/bin/env bash

set -e

export DEBIAN_FRONTEND=noninteractive
USERNAME=${_REMOTE_USER:-"vscode"}

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
    su "${USERNAME}" -c "Rscript -e 'renv::init(bare = FALSE)'"
    su "${USERNAME}" -c "Rscript -e 'renv::install(\"rmarkdown\")'"
    su "${USERNAME}" -c "Rscript -e 'renv::snapshot(type = \"all\")'"
  fi
}

initialise_python() {
  if [ "$FORCE" = true ] || [ ! -f "requirements.txt" ]; then
    su "${USERNAME}" -c "python3 -m venv .venv"
    su "${USERNAME}" -c "source .venv/bin/activate"
    su "${USERNAME}" -c "python3 -m pip install jupyter"
    su "${USERNAME}" -c "python3 -m pip freeze > requirements.txt"
  fi
}

initialise_julia() {
  if [ "$FORCE" = true ] || [ ! -f "Project.toml" ]; then
    su "${USERNAME}" -c "julia -e 'using Pkg; Pkg.activate(\".\"); Pkg.instantiate()'"
    su "${USERNAME}" -c "julia --project=. -e 'using Pkg; Pkg.add("IJulia")'"
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

mkdir -p ${_REMOTE_USER_HOME}/quarto-env
cd ${_REMOTE_USER_HOME}/quarto-env

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

INIT_ENV_PATH="/usr/local/share/init-env.sh"

tee "${INIT_ENV_PATH}" > /dev/null \
<< EOF
#!/usr/bin/env bash
set -e
EOF

tee -a "${INIT_ENV_PATH}" > /dev/null \
<< 'EOF'
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --source|-s)
      SOURCE_DIR="$2"
      shift
      ;;
    --target|-t)
      TARGET_DIR="$2"
      ;;
    *)
      echo "Unknown parameter passed: $1"
      show_help
      exit 1
      ;;
  esac
  shift
done

for item in "${SOURCE_DIR}"/*; do
  ln -sf "${item}" "${TARGET_DIR}/"
done
EOF

chmod 755 "${INIT_ENV_PATH}"
