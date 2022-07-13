// parameters
gitUser        = 'UBC-Stat-ML'
gitRepoName    = 'NRSTExp'

workflow {
  // run the process
  setupPkg() | runExp
}

process setupPkg {  
  label 'local_job'
  output:
    path 'jldepot'
  script:
    template 'cloneRepoAndSetupDepot.sh'
}

process runExp {
  label 'parallel_job'
  input:
    path jldepot
  output:
    stdout

  """
  JULIA_DEPOT_PATH=$jldepot julia --project=${gitRepoName} -e "println(\"loading pkg...\");using ${gitRepoName};println(\"pkg loaded\")"
  """  
}
