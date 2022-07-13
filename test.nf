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
    path 'code'
  script:
    template 'cloneRepoAndSetupDepot.sh'
}

process runExp {
  label 'parallel_job'
  input:
    path code
  output:
    stdout

  """
  JULIA_DEPOT_PATH=${code}/jldepot julia --project=${code}/${gitRepoName} -e "using ${gitRepoName}; using InteractiveUtils; versioninfo()"
  """  
}
