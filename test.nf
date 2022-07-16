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
    path 'output'
  
  """
  mkdir output
  touch output/${id}_samples.csv
  touch output/${id}_metadata.tsv
  """
}
