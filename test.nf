// parameters
gitUser        = 'UBC-Stat-ML'
gitRepoName    = 'NRSTExp'

workflow {
  // run the process
  setupRepo() | runExp
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
  output:
    stdout

  """
  julia --project=juliapath -e "println('loading pkg...');using ${gitRepoName};println('pkg loaded')"
  """  
}
