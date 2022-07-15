using Pkg
Pkg.add(
  [
    Pkg.PackageSpec(url="git@github.com:miguelbiron/SplittableRandoms.jl.git"),
    Pkg.PackageSpec(url="git@github.com:UBC-Stat-ML/NRST.jl.git"),
    Pkg.PackageSpec(url="git@github.com:UBC-Stat-ML/NRSTExp.git")
  ]
)
Pkg.precompile(strict=true)

