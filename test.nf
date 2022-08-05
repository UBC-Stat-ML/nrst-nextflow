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
  # must use system git for my keys to work: https://discourse.julialang.org/t/julia-repl-is-ignoring-my-ssh-config-file/65287/4
  JULIA_PKG_USE_CLI_GIT=true julia ${jlscdir}/set_up_env.jl
  """
}

