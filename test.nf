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
    val "$gitRepoName"
  script:
    template 'installPkgAndUpdate.sh'
}

process runExp {
  label 'local_job'
  input:
    val pkgName
  output:
    stdout

  """
  julia -e "println(\"loading pkg...\");using ${pkgName};println(\"pkg loaded\")"
  """  
}
