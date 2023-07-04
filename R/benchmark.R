source("utils.R")

# load the latest consolidated file
csvs = list.files(path       = file.path("..","deliverables"),
                  pattern    = '^NRSTExp_benchmark_\\d+.csv$',
                  full.names = TRUE)
dta_our = read.csv(max(csvs)) %>% 
  mutate(tuning = "Ours")

# load the latest consolidated file
csvs = list.files(path       = file.path("..","deliverables"),
                  pattern    = '^NRSTExp_benchOwnTune_\\d+.csv$',
                  full.names = TRUE)
dta_own = read.csv(max(csvs)) %>% 
  mutate(tuning = "Other") %>% 
  filter(proc != "NRST") # would duplicate the same results

dta = bind_rows(dta_our, dta_own)

##############################################################################
# plot: TE/(max V evals) for all models and real samplers
##############################################################################

cost_var = quote(costser)
plt = dta %>% 
  mutate(tgt = eval(cost_var)) %>% #, is_NRST = proc=="NRST") %>% 
  ggplot(aes(x = proc, y=tgt, color=tuning)) +
  geom_boxplot(lwd=0.25) +
  scale_color_discrete(name = "Tuning method") +
  my_scale_y_log10() +
  facet_wrap(~ mod, scales="free_y") +
  my_theme() +
  labs(
    x = "Sampler",
    y = cost_var_label(cost_var)
  )
ggsave("benchmark.pdf", plot = plt, width=6, height = 3, device = cairo_pdf) # device needed on Linux to print unicode correctly

