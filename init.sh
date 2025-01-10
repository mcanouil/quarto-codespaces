#!/usr/bin/env bash


if [ ! -f "renv.lock" ]; then
  Rscript -e 'renv::init(bare = FALSE)'
  Rscript -e 'renv::install("rmarkdown")'
  Rscript -e 'renv::snapshot(type = "all")'
fi

if [ ! -f "requirements.txt" ]; then
  python3 -m venv .venv
  source .venv/bin/activate
  python3 -m pip install jupyter
  python3 -m pip freeze > requirements.txt
fi

if [ ! -f "Project.toml" ]; then
  julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'
  julia --project=. -e 'using Pkg; Pkg.add("IJulia")'
fi
