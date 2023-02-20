#############################################################################
# set up julia
#############################################################################

# remove the general registry to avoid "unsatisfiable requirements" errors
julia -e 'using Pkg; Pkg.Registry.rm("General")'

# must use system git for my keys to work:
# https://discourse.julialang.org/t/julia-repl-is-ignoring-my-ssh-config-file/65287/4
JULIA_PKG_USE_CLI_GIT=true julia ${jlscdir}/set_up_env.jl

# force precompilation to avoid race conditions:
# https://discourse.julialang.org/t/compile-errors-on-hpc/47264/4
julia --project=jlenv -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

#############################################################################
# set up R
#############################################################################

Rscript ${Rscdir}/set_up_env.R

