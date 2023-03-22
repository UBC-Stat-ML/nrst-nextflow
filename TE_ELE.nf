// parameters
params.deliverableDir = 'deliverables/'

// paths
jlScriptsDir_ch= Channel.fromPath('jl', type: 'dir')
rScriptsDir_ch = Channel.fromPath('R', type: 'dir')

include { setupEnv; collectAndProcess } from './modules/building_blocks' params(params)

// modify the usual runExp module to handle the (cor,gam) tuple
process runExp {
  label 'cluster_full_job'
  cpus  { workflow.profile == 'standard' ? 1 : 8 }
  input:
    path jlenv
    each exper
    each model
    each fun
    each xpl
    each xps
    each seed
    tuple val(maxcor), val(gamma)
  output:
    path '*.*'
  script:
    template 'runExp.sh'
}

workflow {
  // define the grid of parameters over which to run the experiments
  exps_ch = Channel.of('TE_ELE')
  mods_ch = Channel.of('Challenger')//'XYModel', 'MRNATrans', 'HierarchicalModel', 'Titanic')
  funs_ch = Channel.of('mean')
  cors_ch = Channel.of(1)//1e-3, 1e-2, 1e-1, 1e0)
  gams_ch = Channel.of(2.5)//2.0, 4.0, 6.0, 8.0)
  xpls_ch = Channel.of('SSSO')
  xpss_ch = Channel.of(0.00001)
  seeds_ch= Channel.of(7634)//,805,1128,599,9766,5040,6523,9883,8405,5618,9924,3739,5404,7022,5301,8870,7456,3198,333,4594,2911,2764,4225,815,5427,65,1164,3509,7469,7627)

  // run process
  // idea: instead of the full factorial cor x gam, only consider the upper
  // and rightmost sides of the square
  cmin = cors_ch.min()
  gmax = gams_ch.max()
  cor_gam_ch = cors_ch.combine(gams_ch)
      .filter { it[0]<=cmin.get() || it[1]>=gmax.get()} // ".get()" extracts the value inside the DataflowVariable types
      
  jlenv_ch = setupEnv(jlScriptsDir_ch, rScriptsDir_ch)
  files_ch = runExp(jlenv_ch, exps_ch, mods_ch, funs_ch, xpls_ch, xpss_ch, seeds_ch, cor_gam_ch)
  collectAndProcess(files_ch.collect(), rScriptsDir_ch)
}

