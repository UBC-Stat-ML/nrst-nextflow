// parameters
gitUser        = 'UBC-Stat-ML'
gitRepoName    = 'NRSTExp'
deliverableDir = 'deliverables/' + workflow.scriptName.replace('.nf','')

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('ess_versus_cost')
  mods_ch = Channel.of('MvNormal')
  cors_ch = Channel.of(0.99)

  // run the process
  ch_juliapath = updateDeps()
  runExp(ch_juliapath, exps_ch, mods_ch, cors_ch)
}

process setupRepo {  
  label 'local_job'
  output:
    path "$gitRepoName"
  script:
    template 'cloneRepoAndUpdate.sh'
}

process runExp {
  label 'parallel_job'
  publishDir deliverableDir, mode: 'copy', overwrite: true
  input:
    path 'juliapath'
    val exper
    val model
    val maxcor
  output:
    path '*.csv'

  """
  julia --project=juliapath -e "using NRSTExp; dispatch()" $exper $model $maxcor
  """  
}
