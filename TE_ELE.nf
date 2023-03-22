// parameters
params.deliverableDir = 'deliverables/'

// paths
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

include { setupEnv; runExp; collectAndProcess } from './modules/building_blocks' params(params)

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('TE_ELE')
  mods_ch = Channel.of('Challenger', 'XYModel', 'MRNATrans', 'HierarchicalModel')
  funs_ch = Channel.of('mean')
  cors_ch = Channel.of(1e-3, 1e-2, 1e-1, 1e0) // hack: cor>=1 gets interpreted as setting fixed nexpl=cor
  gams_ch = Channel.of(2.0, 4.0, 6.0, 8.0)
  xpls_ch = Channel.of('SSSO')
  xpss_ch = Channel.of(0.00001)
  seeds_ch= Channel.of(7634,805,1128,599,9766,5040,6523,9883,8405,5618,9924,3739,5404,7022,5301,8870,7456,3198,333,4594,2911,2764,4225,815,5427,65,1164,3509,7469,7627)

  // run process
  jlenv_ch = setupEnv(jlScriptsDir_ch, rScriptsDir_ch)
  files_ch = runExp(jlenv_ch, exps_ch, mods_ch, funs_ch, cors_ch, gams_ch, xpls_ch, xpss_ch, seeds_ch)
  collectAndProcess(files_ch.collect(), rScriptsDir_ch)
}



