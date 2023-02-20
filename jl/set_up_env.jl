using Pkg

Pkg.Registry.update() # update registry
Pkg.activate("jlenv") # create a dedicated julia environment

# install our packages
# must be done like this in a single call to add to avoid issues with resolving
# dependencies when the pkgs are not registered
Pkg.add(
  [
    Pkg.PackageSpec(url="git@github.com:UBC-Stat-ML/NRST.jl.git"),
    Pkg.PackageSpec(url="git@github.com:UBC-Stat-ML/NRSTExp.git")
  ]
)

