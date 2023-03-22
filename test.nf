workflow {
  // define the grid of parameters over which to run the experiments
  cors_ch = Channel.of(1e-4, 1e-3, 1e-2, 1e-1)
  gams_ch = Channel.of(2.0, 4.0, 6.0, 8.0)
  
  // run process
  cmin = cors_ch.min()
  gmax = gams_ch.max()
  cor_gam_ch = cors_ch.combine(gams_ch)
      .filter { it[0]<=cmin.get() || it[1]>=gmax.get()}
      .view()
}

