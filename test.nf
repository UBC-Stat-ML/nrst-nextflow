// repo information
gitUser     = 'UBC-Stat-ML'
gitRepoName = 'NRSTExp'

workflow {
  setupRepo() | view
}

process setupRepo {  
  label 'local_job'
  output:
  path gitRepoName
  script:
  template 'cloneRepoAndUpdate.sh'
}
