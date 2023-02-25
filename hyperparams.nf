// parameters
params.deliverableDir = 'deliverables/'

// paths
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

include { setupEnv; runExp; collectAndProcess } from './modules/building_blocks' params(params)

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('hyperparams')
  mods_ch = Channel.of('Challenger', 'XYModel', 'MRNATrans', 'HierarchicalModel', 'Titanic')
  funs_ch = Channel.of('mean', 'median')
  cors_ch = Channel.of(0.80, 0.85, 0.90, 0.95)
  gams_ch = Channel.of(1.0, 1.5, 2.0, 2.5, 3.0)
  xpls_ch = Channel.of('SSSO')
  xpss_ch = Channel.of(0.00001)
  seeds_ch= Channel.of(7008, 26, 4277, 2986, 3241, 7194, 7496, 2461, 9521, 2639, 8970, 4330, 5412, 799, 6488, 4729, 1018, 2792, 5003, 9216, 9989, 6323, 3802, 5635, 351, 8908, 5564, 2370, 6872, 1420)

  // run process
  jlenv_ch = setupEnv(jlScriptsDir_ch, rScriptsDir_ch)
  files_ch = runExp(jlenv_ch, exps_ch, mods_ch, funs_ch, cors_ch, gams_ch, xpls_ch, xpss_ch, seeds_ch)
  collectAndProcess(files_ch.collect(), rScriptsDir_ch)
}


