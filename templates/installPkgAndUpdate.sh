#!/usr/bin/env bash

set -e

#gitUser='UBC-Stat-ML'
#gitRepoName='NRSTExp'
#echo "using Pkg; Pkg.add(url=\"${gitRepoURL}\"); Pkg.update(); using ${gitRepoName}"
julia -e "using Pkg; Pkg.add(url=\"git@github.com:${gitUser}/${gitRepoName}.git\"); Pkg.update(); using ${gitRepoName}"

