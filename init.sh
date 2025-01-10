#!/usr/bin/env bash

Rscript -e 'renv::init(bare = FALSE)'
Rscript -e 'renv::install("rmarkdown")'

python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install jupyter

julia -e 'using Pkg; Pkg.add("IJulia")'
