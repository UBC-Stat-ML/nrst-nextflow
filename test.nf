workflow {
  testProc \
    | view
}

process testProc {  
  label 'local'
  cpus  { workflow.profile == 'standard' ? 1 : (workflow.scriptName == 'test.nf' ? 8 : 16) }
  output:
    stdout
  
  """
  echo $workflow.profile
  echo $workflow.scriptName
  echo ${task.cpus}
  """
}

