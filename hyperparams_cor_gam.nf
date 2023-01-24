// parameters
params.deliverableDir = 'deliverables/'

// paths
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

include { setupEnv; runExp; collectAndProcess } from './modules/building_blocks' params(params)

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('hyperparams')
  mods_ch = Channel.of('XYModel', 'MRNATrans', 'HierarchicalModel')
  funs_ch = Channel.of('mean', 'median')
  cors_ch = Channel.of(0.8, 0.9, 0.95)
  gams_ch = Channel.of(15.0, 20.0, 25.0, 30.0)
  xpss_ch = Channel.of(0.01, 0.05, 0.1)
  seeds_ch= Channel.of(2798, 7302, 8054, 552, 9429, 6903, 5218, 1208, 8124, 5842, 1198, 9168, 968, 5661, 9895, 4327, 3579, 4537, 7783, 1746, 4851, 1971, 6012, 8604, 7851, 2796, 5410, 1884, 765, 9444)

  // run process
  jlenv_ch = setupEnv(jlScriptsDir_ch, rScriptsDir_ch)
  files_ch = runExp(jlenv_ch, exps_ch, mods_ch, funs_ch, cors_ch, gams_ch, xpss_ch, seeds_ch)
  collectAndProcess(files_ch.collect(), rScriptsDir_ch)
}



