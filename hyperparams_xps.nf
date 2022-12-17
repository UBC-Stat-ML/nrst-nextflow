// parameters
params.deliverableDir = 'deliverables/'

// paths
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

include { setupEnv; runExp; collectAndProcess } from './modules/building_blocks' params(params)

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('hyperparams')
  mods_ch = Channel.of('XYModel_small', 'MRNATrans')//'HierarchicalModel', 'MvNormal', 'XYModel_small', 'Challenger', 'MRNATrans')
  funs_ch = Channel.of('mean')
  cors_ch = Channel.of(0.5)
  gams_ch = Channel.of(10.0)
  xpss_ch = Channel.of(3, 5, 7, 9, 11, 13, 15, 17, 19, 21)
  seeds_ch= Channel.of(568450, 785020, 642301, 831013, 243686, 477000, 501031, 850520, 782204, 318627, 499038, 141573, 712198, 560978, 313174, 162095, 700124, 864606, 993573, 290162, 336877, 315952, 821257, 783635, 715188, 384239, 366990, 109722, 406615, 280402)

  // run process
  jlenv_ch = setupEnv(jlScriptsDir_ch, rScriptsDir_ch)
  files_ch = runExp(jlenv_ch, exps_ch, mods_ch, funs_ch, cors_ch, gams_ch, xpss_ch, seeds_ch)
  collectAndProcess(files_ch.collect(), rScriptsDir_ch)
}

