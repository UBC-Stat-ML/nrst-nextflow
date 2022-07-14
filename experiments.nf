// parameters
gitUser        = 'UBC-Stat-ML'
gitRepoName    = 'NRSTExp'
deliverableDir = 'deliverables/'
R_scripts_dir  = 'R/'

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('ess_versus_cost')
  mods_ch = Channel.of('MvNormal')//, 'XYModel', 'HierarchicalModel')
  cors_ch = Channel.of(0.99)//0.01, 0.1, 0.25, 0.5, 0.75, 0.9, 0.99)

  // run the process
  code_ch = setupPkg()
  out_ch  = runExp(code_ch, exps_ch, mods_ch, cors_ch)
  makePlots(out_ch) | view
}

process setupPkg {  
  label 'local_job'
  output:
    path 'code'
  script:
    template 'cloneRepoAndSetupDepot.sh'
}

process runExp {
  label 'parallel_job'
  input:
    path code
    val exper
    val model
    val maxcor
  output:
    path 'output'

  """
  JULIA_DEPOT_PATH=${code}/jldepot julia -t auto --project=${code}/${gitRepoName} \
      -e "using ${gitRepoName}; dispatch()" $exper $model $maxcor
  """  
}

// TODO: should dispatch one job for each different experiment
// perhaps runExp should produce one folder per experiment inside output dir?
process makePlots {
  label 'parallel_job'
  conda 'r r-dplyr r-ggplot2 r-scales r-stringr r-tidyr'
  publishDir deliverableDir, mode: 'copy', overwrite: true
  input:
    path outdir
  output:
    path '*.pdf'

  """
  OUTDIR=${outdir} Rscript ${R_scripts_dir}/ess_versus_cost_plot.R
  """  
}

