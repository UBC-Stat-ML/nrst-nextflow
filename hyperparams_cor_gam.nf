// parameters
params.deliverableDir = 'deliverables/'

// paths
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

include { setupEnv; runExp; collectAndProcess } from './modules/building_blocks' params(params)

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('hyperparams')
  mods_ch = Channel.of('HierarchicalModel', 'MvNormal', 'XYModel_small', 'Challenger', 'MRNATrans')
  funs_ch = Channel.of('mean')
  cors_ch = Channel.of(0.4, 0.5, 0.6, 0.7, 0.8, 0.9)
  gams_ch = Channel.of(2.0, 4.0, 6.0, 8.0, 10.0, 12.0)
  xpss_ch = Channel.of(3)
  seeds_ch= Channel.of(3947,8378,4253,4998,5500,4794,2140,8181,8228,721,9673,9114,9499,8371,8524,7356,6708,5269,3326,9186,8071,8375,5760,4625,8978,4340,1024,2587,104,3427)

  // run process
  jlenv_ch = setupEnv(jlScriptsDir_ch, rScriptsDir_ch)
  files_ch = runExp(jlenv_ch, exps_ch, mods_ch, funs_ch, cors_ch, gams_ch, xpss_ch, seeds_ch)
  collectAndProcess(files_ch.collect(), rScriptsDir_ch)
}



