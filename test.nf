params {
  gitUser     = 'UBC-Stat-ML'
  gitRepoName = 'NRSTExp'
}
workflow {
  build() | view
}
process setupRepo {  
  label 'local_job'
  output:
  path gitRepoName
  script:
  template 'cloneRepoAndUpdate.sh'
}
