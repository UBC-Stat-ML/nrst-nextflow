using Pkg

if Base.find_package("NRSTExp") == nothing
    Pkg.add(
      [
        Pkg.PackageSpec(url="git@github.com:miguelbiron/SplittableRandoms.jl.git"),
        Pkg.PackageSpec(url="git@github.com:UBC-Stat-ML/NRST.jl.git"),
        Pkg.PackageSpec(url="git@github.com:UBC-Stat-ML/NRSTExp.git")
      ]
    )
end
Pkg.update()

