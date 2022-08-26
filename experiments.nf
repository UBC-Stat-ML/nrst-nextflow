// parameters
deliverableDir = 'deliverables/'
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('ess_versus_cost')
  mods_ch = Channel.of('HierarchicalModel', 'MvNormal', 'XYModel', 'Challenger')
  cors_ch = Channel.of(0.4, 0.6, 0.8, 0.9, 0.99, 1.0)
  
  // run process
  jlenv_ch = setupJlEnv(jlScriptsDir_ch)
  files_ch = runExp(jlenv_ch, exps_ch, mods_ch, cors_ch)
  makePlots(files_ch.collect(), rScriptsDir_ch)
}

process setupJlEnv {  
  label 'local_job'
  input:
    path jlscdir
  output:
    path 'jlenv'
  
  """
  # must use system git for my keys to work:
  # https://discourse.julialang.org/t/julia-repl-is-ignoring-my-ssh-config-file/65287/4
  JULIA_PKG_USE_CLI_GIT=true julia ${jlscdir}/set_up_env.jl
  
  # force precompilation to avoid race conditions:
  # https://discourse.julialang.org/t/compile-errors-on-hpc/47264/4
  julia --project=jlenv -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
  """
}

process runExp {
  label 'pbs_full_job'
  input:
    path jlenv
    each exper
    each model
    each maxcor
  output:
    path '*.*'

  """
  julia --project=$jlenv -t auto \
      -e "using NRSTExp; dispatch()" $exper $model $maxcor
  """
}

// TODO: should dispatch one job for each different experiment, with different script
process makePlots {
  label 'pbs_light_job'
  publishDir deliverableDir, mode: 'copy', overwrite: true
  input:
    path allfiles
    path Rscdir
  output:
    path '*.pdf'
    // path('*.csv', includeInputs: true)
    // path('*.tsv', includeInputs: true)
  """
  Rscript ${Rscdir}/ess_versus_cost_plot.R
  """
}

