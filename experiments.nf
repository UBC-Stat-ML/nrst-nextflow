// parameters
gitUser        = 'UBC-Stat-ML'
gitRepoName    = 'NRSTExp'
deliverableDir = workflow.launchDir + '/deliverables'

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('ess_versus_cost')
  mods_ch = Channel.of('MvNormal')
  cors_ch = Channel.of(0.99)

  // run the process
  code_ch = setupPkg()
  runExp(code_ch, exps_ch, mods_ch, cors_ch)
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
  publishDir deliverableDir, mode: 'copy', overwrite: true
  input:
    path code
    val exper
    val model
    val maxcor
  output:
    path '*.csv'

  """
  JULIA_DEPOT_PATH=${code}/jldepot julia --project=${code}/${gitRepoName} -e "using ${gitRepoName}; dispatch()" $exper $model $maxcor
  """  
}
