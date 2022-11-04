// parameters
deliverableDir = 'deliverables/'
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('benchmark')
  mods_ch = Channel.of('HierarchicalModel', 'MvNormal', 'XYModel', 'Challenger')
  funs_ch = Channel.of('mean', 'median')
  cors_ch = Channel.of(0.8) //, 0.9, 0.99, 1.0)
  gams_ch = Channel.of(1.0, 2.0)
  seeds_ch= Channel.of(1)//3990, 5057, 8585, 7265, 4468, 9334, 3641, 6101, 2721, 4855, 4787, 4022, 4477, 4202, 6729, 4235, 4428, 6422, 1555, 797, 2320, 3804, 8006, 6459, 2701, 3462, 3121, 6927, 4582, 5351)

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
  julia --project=$jlenv -t 10 \
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

