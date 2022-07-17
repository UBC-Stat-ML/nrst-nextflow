workflow {
  Channel.of(1..7) \
    | mkFiles \
    | collect \
    | view
}

process mkFiles {  
  label 'parallel_job'
  input:
    each id
  output:
    path '*.*'
  
  """
  touch ${id}_samples.csv
  touch ${id}_metadata.tsv
  """
}

process countFiles {  
  label 'local_job'
  input:
    path '*.*'
  
  """
  ls -1 *.csv| wc -l
  ls -1 *.tsv| wc -l
  ls -1 | wc -l
  """
}
