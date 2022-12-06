library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)

# load the latest consolidated file
csvs = list.files(path       = file.path("..","deliverables"),
                  pattern    = '^NRSTExp_benchmark_\\d+.csv$',
                  full.names = TRUE)
dta  = read.csv(max(csvs))

# parameters
TE_min = 5e-4

##############################################################################
# plot: TE/(max V evals) for all models and real samplers
##############################################################################

dta %>% 
  filter(!(proc %in% c("DTPerf", "DTAct"))) %>% 
  mutate(tgt = TE/costpar) %>% 
  ggplot(aes(x = proc, y=tgt)) +
  geom_boxplot() +
  scale_y_log10() +
  facet_wrap(~ mod, scales="free_y", nrow = 1) +
  theme_bw() +
  labs(
    x = "Sampler",
    y = "Efficiency = TE/max(number of V(x) evals.)"
  )
