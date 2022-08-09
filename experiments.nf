// parameters
deliverableDir = 'deliverables/'
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('ess_versus_cost')
  mods_ch = Channel.of('MvNormal', 'XYModel') // 'HierarchicalModel'
  cors_ch = Channel.of(0.2, 0.5, 0.75, 0.9, 0.99)
  
  // run process
  done_ch  = setupJlEnv(jlScriptsDir_ch)
  files_ch = runExp(done_ch, exps_ch, mods_ch, cors_ch)
  makePlots(files_ch.collect(), rScriptsDir_ch) | view
}

process setupJlEnv {  
  label 'local_job'
  input:
    path jlscdir
  output:
    val true
  
  """
  # must use system git for my keys to work: https://discourse.julialang.org/t/julia-repl-is-ignoring-my-ssh-config-file/65287/4
  JULIA_PKG_USE_CLI_GIT=true julia ${jlscdir}/set_up_env.jl
  """
}

process runExp {
  label 'pbs_full_job'
  input:
    val done
    each exper
    each model
    each maxcor
  output:
    path '*.*'

  """
  # disable cache to avoid race conditions in writing to it: https://discourse.julialang.org/t/precompilation-error-using-hpc/17094/3
  # name of that option changed: https://github.com/JuliaLang/julia/issues/23054 
  julia --compiled-modules=no -t auto \
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
  """
  Rscript ${Rscdir}/ess_versus_cost_plot.R
  """
}

