# load utility functions
script_path = commandArgs(trailingOnly=TRUE)
in_workflow = length(script_path) > 0
if(!in_workflow) script_path = "."
source(file.path(script_path, "utils.R"))

# load the latest consolidated file
data_path = ifelse(in_workflow, ".", file.path("..","deliverables"))
csvs = list.files(path       = data_path,
                  pattern    = '^NRSTExp_benchmark_\\d+.csv$',
                  full.names = TRUE)
dta_our = read.csv(max(csvs)) %>% 
  mutate(tuning = "Ours")

# load the latest consolidated file
csvs = list.files(path       = data_path,
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
  ggplot(aes(x = proc, y=tgt, color=tuning))+#, linetype=tuning)) +
  geom_boxplot(lwd=0.3,  outlier.size = 1,width=0.9, position="dodge")+#(padding=0)) +
  scale_color_discrete(name = "Tuning method") +
  # scale_linetype_manual(name = "Tuning method", values=c("dotted","solid")) +
  # scale_y_log10(breaks=scales::log_breaks(), labels=scales::label_log()) +
  my_scale_y_log10(digits=0)+
  facet_wrap(~ mod, scales="free_y") +
  my_theme() +
  labs(
    x = "Sampler",
    y = cost_var_label(cost_var)
  )
# plt
ggsave("benchmark.pdf", plot = plt, width=6, height = 3, device = cairo_pdf) # device needed on Linux to print unicode correctly

