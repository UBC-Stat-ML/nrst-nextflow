// parameters
params.deliverableDir = 'deliverables/'

// paths
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

include { setupEnv; runExp; collectAndProcess } from './modules/building_blocks' params(params)

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('benchmark')
  mods_ch = Channel.of('HierarchicalModel', 'XYModel_big', 'Challenger', 'MRNATrans', 'Titanic')
  funs_ch = Channel.of('mean')
  cors_ch = Channel.of(0.6)
  gams_ch = Channel.of(25.0)
  xpss_ch = Channel.of(0.1)
  seeds_ch= Channel.of(40378,40322,75611,72267,39092,22982,72984,44550,60144,66921,55293,15998,20975,48496,16905,97508,47257,53601,74852,89440,69929,99540,48775,65873,51393,87895,44991,24482,47498,48961)

  // run process
  jlenv_ch = setupEnv(jlScriptsDir_ch, rScriptsDir_ch)
  files_ch = runExp(jlenv_ch, exps_ch, mods_ch, funs_ch, cors_ch, gams_ch, xpss_ch, seeds_ch)
  collectAndProcess(files_ch.collect(), rScriptsDir_ch)
}

