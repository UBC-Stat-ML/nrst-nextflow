using Pkg

# create a new julia environment
Pkg.activate("jlenv")

# install our packages
# must be done like this in a single call to add to avoid issues with resolving
# dependencies when the pkgs are not registered
Pkg.add(
  [
    Pkg.PackageSpec(url="git@github.com:miguelbiron/SplittableRandoms.jl.git"),
    Pkg.PackageSpec(url="git@github.com:UBC-Stat-ML/NRST.jl.git"),
    Pkg.PackageSpec(url="git@github.com:UBC-Stat-ML/NRSTExp.git")
  ]
)

