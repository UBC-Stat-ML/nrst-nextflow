// parameters
deliverableDir = 'deliverables/'
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('ess_versus_cost')
  mods_ch = Channel.of('MvNormal')//, 'XYModel', 'HierarchicalModel')
  cors_ch = Channel.of(0.01, 0.1, 0.25, 0.5, 0.75, 0.9, 0.99)
  
  // run process
  done_ch  = setupJlEnv(jlScriptsDir_ch)
  out_ch   = runExp(done_ch, exps_ch, mods_ch, cors_ch)
  makePlots(out_ch, rScriptsDir_ch) | view
}

process setupJlEnv {  
  label 'local_job'
    input:
    path jlscdir
  output:
    val true
  
  """
  julia ${jlscdir}/set_up_env.jl
  """
}

process runExp {
  label 'parallel_job'
  input:
    val done
    each exper
    each model
    each maxcor
  output:
    path 'output'

  """
  # disable cache to avoid race conditions in writing to it: https://discourse.julialang.org/t/precompilation-error-using-hpc/17094/3
  julia --compilecache=no -t auto \
      -e "using NRSTExp; dispatch()" $exper $model $maxcor
  """
}

// TODO: should dispatch one job for each different experiment, with different script
// perhaps runExp should produce one folder per experiment inside output dir?
process makePlots {
  label 'parallel_job'
  conda 'r r-dplyr r-ggplot2 r-scales r-stringr r-tidyr'
  publishDir deliverableDir, mode: 'copy', overwrite: true
  input:
    path outdir
    path Rscdir
  output:
    path '*.pdf'
  """
  OUTDIR=${outdir} Rscript ${Rscdir}/ess_versus_cost_plot.R
  """
}

