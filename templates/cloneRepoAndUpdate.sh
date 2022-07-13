#!/usr/bin/env bash

set -e

git clone git@github.com:/${gitUser}/${gitRepoName}
cd ${gitRepoName}
julia --project -e "using Pkg; Pkg.update()"

