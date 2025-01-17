process setupEnv {  
  debug 'true'
  label 'local_job'
  input:
    path jlscdir
    path Rscdir
  output:
    path 'jlenv'
  script:
    template 'setupEnv.sh'
}

process runExp {
  label 'cluster_full_job'
  cpus  { workflow.profile == 'standard' ? 1 : 4 }
  memory { workflow.scriptName == 'TE_ELE.nf' ? 8.GB : 4.GB }
  input:
    path jlenv
    each sampler
    each exper
    each model
    each fun
    each maxcor
    each gamma
    each xpl
    each xps
    each seed
  output:
    path '*.*'
  script:
    template 'runExp.sh'
}

process collectAndProcess {
  label 'cluster_light_job'
  publishDir params.deliverableDir, mode: 'copy', overwrite: true
  input:
    path allfiles
    path Rscdir
  output:
    path '*.csv'
    // path '*.pdf'
    // path('*.csv', includeInputs: true)
    // path('*.tsv', includeInputs: true)
  """
  Rscript ${Rscdir}/consolidate.R
  """
}

