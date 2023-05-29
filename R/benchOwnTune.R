source("utils.R")

# load the latest consolidated file
csvs = list.files(path       = file.path("..","deliverables"),
                  pattern    = '^NRSTExp_benchOwnTune_\\d+.csv$',
                  full.names = TRUE)
dta  = read.csv(max(csvs))

##############################################################################
# plot: TE/(max V evals) for all models and real samplers
##############################################################################

cost_var = quote(costser)
dta %>% 
  mutate(tgt = eval(cost_var), is_NRST = sam=="NRST") %>% 
  ggplot(aes(x = sam, y=tgt, color=is_NRST)) +
  geom_boxplot(lwd=0.25, show.legend=FALSE) +
  scale_color_manual(values = c("black", "blue")) +
  my_scale_y_log10() +
  facet_wrap(~ mod, scales="free_y") +
  my_theme() +
  labs(
    x = "Sampler",
    y = cost_var_label(cost_var)
  )
ggsave("benchOwnTune.pdf", width=6, height = 3, device = cairo_pdf) # device needed on Linux to print unicode correctly

