// parameters
deliverableDir = 'deliverables/'
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('benchmark')
  mods_ch = Channel.of('MRNATrans')// 'HierarchicalModel', 'MvNormal', 'XYModel', 'Challenger', 'MRNATrans')
  funs_ch = Channel.of('median')//, 'mean')
  cors_ch = Channel.of(0.9)//0.5, 0.6, 0.7, 0.8)
  gams_ch = Channel.of(3.0)//, 3.0, 4.0, 5.0, 6.0)
  seeds_ch= Channel.of(4253)//3947,8378,4253,4998,5500,4794,2140,8181,8228,721,9673,9114,9499,8371,8524,7356,6708,5269,3326,9186,8071,8375,5760,4625,8978,4340,1024,2587,104,3427)

  // run process
  jlenv_ch = setupJlEnv(jlScriptsDir_ch)
  files_ch = runExp(jlenv_ch, exps_ch, mods_ch, funs_ch, cors_ch, gams_ch, seeds_ch)
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
    each fun
    each maxcor
    each gamma
    each seed
  output:
    path '*.*'

  """
  JULIA_DEBUG=NRST julia --project=$jlenv -t 8 \
      -e "using NRSTExp; dispatch()" exp=$exper mod=$model fun=$fun cor=$maxcor gam=$gamma seed=$seed
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
    path '*.csv'
    // path '*.pdf'
    // path('*.csv', includeInputs: true)
    // path('*.tsv', includeInputs: true)
  """
  Rscript ${Rscdir}/consolidate.R
  """
}

