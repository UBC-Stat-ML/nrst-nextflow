#!/usr/bin/env bash

set -e

git clone git@github.com:${gitUser}/${gitRepoName}
julia --project=${gitRepoName} -e "using Pkg; Pkg.update(); Pkg.precompile(strict=true)"

