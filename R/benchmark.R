source("utils.R")

# load the latest consolidated file
csvs = list.files(path       = file.path("..","deliverables"),
                  pattern    = '^NRSTExp_benchmark_\\d+.csv$',
                  full.names = TRUE)
dta  = read.csv(max(csvs))

##############################################################################
# plot: TE/(max V evals) for all models and real samplers
##############################################################################

cost_var = quote(costser)
dta %>% 
  mutate(tgt = eval(cost_var)) %>% 
  ggplot(aes(x = proc, y=tgt)) +
  geom_boxplot() +
  scale_y_log10(
    breaks = log10_breaks,
    labels = scales::trans_format("log10", scales::label_math(format=function(x){sprintf("%.1f",x)}))
  ) +
  facet_wrap(~ mod, scales="free_y") +
  theme_bw() +
  labs(
    x = "Sampler",
    y = cost_var_label(cost_var)
  )
ggsave("benchmark.pdf", width=6, height = 4, device = cairo_pdf) # device needed on Linux to print unicode correctly

