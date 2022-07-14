deliverableDir = 'deliverables/'

workflow {
  makePlots | view
}

process makePlots {
  label 'parallel_job'
  conda 'r r-dplyr r-ggplot2 r-scales r-stringr r-tidyr'
  publishDir deliverableDir, mode: 'copy', overwrite: true
  output:
    path '*.pdf'

  """
  #!/usr/bin/env Rscript
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(stringr)
  library(tidyr)

  plt = ggplot(mpg, aes(displ, hwy, colour = class)) + 
    geom_point()
  ggsave("mpg.pdf", plot=plt)
  """
}
