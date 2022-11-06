workflow {
  testProc \
    | view
}

process testProc {  
  label 'pbs_light_job'
  output:
    stdout
  
  """
  printenv | grep PBS
  """
}

