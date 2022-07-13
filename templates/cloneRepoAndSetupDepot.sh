#!/usr/bin/env bash

set -e

# clone repo and install it to a fresh depot in scratch space
mkdir code
cd code
git clone git@github.com:${gitUser}/${gitRepoName}
mkdir jldepot
JULIA_DEPOT_PATH=jldepot julia --project=${gitRepoName} -e "using Pkg; Pkg.update()"
cd ..

