// parameters
params.deliverableDir = 'deliverables/'

// paths
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

include { setupEnv } from './modules/building_blocks' params(params)
include { runExp as runExpOur; collectAndProcess as collectAndProcessOur } from './modules/building_blocks' params(params)
include { runExp as runExpOwn; collectAndProcess as collectAndProcessOwn } from './modules/building_blocks' params(params)

workflow {
  // commont grid of parameters for both experiments
  mods_ch = Channel.of('XYModel', 'MRNATrans', 'HierarchicalModel', 'Funnel', 'Banana', 'ThresholdWeibull')
  funs_ch = Channel.of('mean')
  cors_ch = Channel.of(0.95)
  gams_ch = Channel.of(2)
  xpls_ch = Channel.of('SSSO')
  xpss_ch = Channel.of(0.00001)
  seeds_ch = Channel.of(40378,40322,75611,72267,39092,22982,72984,44550,60144,66921,55293,15998,20975,48496,16905,97508,47257,53601,74852,89440,69929,99540,48775,65873,51393,87895,44991,24482,47498,48961)

  // setup environment
  jlenv_ch = setupEnv(jlScriptsDir_ch, rScriptsDir_ch)
  
  // run samplers with our tuning
  samplers_our = Channel.of('NRST') // we use NRST tuning so the other samplers have to be created inside
  exp_our      = Channel.of('benchmark')
  files_our    = runExpOur(jlenv_ch, samplers_our, exp_our, mods_ch, funs_ch, cors_ch, gams_ch, xpls_ch, xpss_ch, seeds_ch)
  csv_our      = collectAndProcessOur(files_our.collect(), rScriptsDir_ch)
  
  // run samplers with their own tuning
  samplers_own = Channel.of('GT95','FBDR','SH16') // no need to run NRST again here
  exp_own      = Channel.of('benchOwnTune')
  files_own    = runExpOwn(jlenv_ch, samplers_own, exp_own, mods_ch, funs_ch, cors_ch, gams_ch, xpls_ch, xpss_ch, seeds_ch)
  csv_own      = collectAndProcessOwn(files_own.collect(), rScriptsDir_ch)
  
  // plot
  benchmarkPlot(csv_our, csv_own, rScriptsDir_ch)
}

process benchmarkPlot {
  //debug 'true'
  label 'cluster_light_job'
  publishDir params.deliverableDir, mode: 'copy', overwrite: true
  input:
    path csv_our
    path csv_own
    path Rdir
  output:
    path '*.pdf'
  """
  Rscript ${Rdir}/benchmark.R ${Rdir}
  """
}

