// parameters
params.deliverableDir = 'deliverables/'

// paths
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

include { setupEnv } from './modules/building_blocks' params(params)

workflow {
  jlenv_ch = setupEnv(jlScriptsDir_ch, rScriptsDir_ch)

  // Figure 1: example index processes
  indexProcessPlot(jlenv_ch)
  
  // Figure 2: barriers
  barrier_data = barrierData(jlenv_ch)
  barrierPlot(barrier_data, rScriptsDir_ch)
}

process indexProcessPlot {
  debug 'true'
  label 'local_job'
  publishDir params.deliverableDir, mode: 'copy', overwrite: true
  input:
    path jlenv
  output:
    path '*.pdf'
  """
  julia --project=$jlenv -e 'using NRSTExp; gen_iproc_plots()'
  """
}

process barrierData {
  debug 'true'
  label 'local_job'
  input:
    path jlenv
  output:
    path '*.csv'
  """
  julia --project=$jlenv -e 'using NRSTExp; NRSTExp.get_barrier_df()'
  """
}

process barrierPlot {
  debug 'true'
  label 'local_job'
  publishDir params.deliverableDir, mode: 'copy', overwrite: true
  input:
    path barrier_data
    path Rdir
  output:
    path '*.pdf'
  """
  Rscript ${Rdir}/barriers.R ${Rdir}
  """
}


