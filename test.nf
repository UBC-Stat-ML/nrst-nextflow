jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
workflow {
  jlScriptsDir_ch \
    | setupJlEnv \
    | view
}

process setupJlEnv {  
  label 'local_job'
  conda 'conda-jl-env.yml'
  input:
    path jlscdir
  output:
    val true
  
  """
  julia ${jlscdir}/set_up_env.jl
  """
}

