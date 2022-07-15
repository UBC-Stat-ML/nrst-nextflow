jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')

workflow {
  setupJlEnv(jlScriptsDir_ch) | view
}

process setupJlEnv {  
  label 'local_job'
    input:
    path jlscdir
  output:
    path 'jldepot'
  
  """
  mkdir jldepot
  JULIA_DEPOT_PATH=jldepot julia ${jlscdir}/set_up_env.jl
  JULIA_DEPOT_PATH=jldepot julia -e "using NRSTExp"
  """
}
