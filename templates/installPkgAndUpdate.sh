#!/usr/bin/env bash

set -e

julia -e "using Pkg; Pkg.add(url=\"git@github.com:${gitUser}/${gitRepoName}.git\"); Pkg.update(); using ${gitRepoName}"

