#!/usr/bin/env bash

set -e

#gitUser='UBC-Stat-ML'
#gitRepoName='NRSTExp'
gitRepoURL="git@github.com:${gitUser}/${gitRepoName}.git"
#echo "using Pkg; Pkg.add(url=\"${gitRepoURL}\"); Pkg.update(); using ${gitRepoName}"
julia -e "using Pkg; Pkg.add(url=\"${gitRepoURL}\"); Pkg.update(); using ${gitRepoName}"

