library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)

# load the latest consolidated file
csvs = list.files(path       = file.path("..","deliverables"),
                  pattern    = '^NRSTExp_hyperparams_\\d+.csv$',
                  full.names = TRUE)
dta  = read.csv(max(csvs))#csvs[2])#)

# parameters
TE_min = 5e-4

##############################################################################
# plot: TE/(max V evals) for all combinations and models
##############################################################################

cor_gam_labs = labeller(
  cor = function(co){paste("Max. Corr. =", co)},
  gam = function(ga){paste0("γ = ",ga," (N ≈ ", 2*as.integer(ga),"Λ)")}
)

dta %>% 
  filter(proc == "NRST") %>% 
  mutate(tgt = TE/costpar) %>% 
  ggplot(aes(y = as.factor(cor), x = tgt, color = fun)) +
  geom_boxplot() +
  geom_point(stat = "summary", fun = "mean", shape = "cross",
             position = position_dodge2(width=0.8)) + 
  scale_x_log10() +
  scale_color_discrete(name="Strategy",
                       labels=c("mean"="Mean", "median"="Median")) +
  facet_grid(gam ~ mod, labeller = cor_gam_labs, scales="free_x") +
  theme_bw() +
  labs(
    x = "Efficiency = TE/max(number of V(x) evals.)",
    y = "Maximum correlation"
  )

#######################################
# find the most robust combination:
# maximize the p5 across repetitions
#######################################

# find combinations that never gave TEs lower than limit
valid_combs = dta %>% 
  filter(fun=="mean" & proc == "NRST") %>% 
  group_by(mod,cor,gam) %>% 
  summarise(n_valid_TE = sum(TE > TE_min)) %>% 
  ungroup() %>% 
  filter(n_valid_TE == max(n_valid_TE)) %>% 
  select(-n_valid_TE)

summ=dta %>% 
  filter(fun == "mean" & proc == "NRST") %>% 
  inner_join(valid_combs) %>% 
  mutate(tgt = TE/costpar) %>%
  group_by(mod,cor,gam) %>% 
  # compute aggregates over replications (seeds)
  summarise(agg_tgt = quantile(tgt,0.05)) %>% 
  ungroup() %>% 
  # group_by(mod) %>%
  # slice_max(agg_tgt,n=3)
  inner_join(
    (.) %>% 
      group_by(mod) %>%  
      slice_max(agg_tgt,n=1) %>% 
      select(max_agg_tgt=agg_tgt),
    by="mod") %>% 
  mutate(ratio = agg_tgt/max_agg_tgt) %>% 
  group_by(cor,gam) %>% 
  summarise(mean_ratio=mean(ratio)) %>% 
  arrange(desc(mean_ratio))
summ # (cor, gam) = (0.7, 6)

##############################################################################
# xps-only 
##############################################################################

dta %>% 
  filter(!(proc %in% c("DTPerf", "DTAct"))) %>% 
  mutate(tgt = TE/costpar) %>% 
  ggplot(aes(x = as.factor(xps), y=tgt)) +
  geom_boxplot() +
  scale_y_log10() +
  facet_wrap(~ mod, scales="free_y", nrow = 1) +
  theme_bw() +
  labs(
    x = "Sampler",
    y = "Efficiency = TE/max(number of V(x) evals.)"
  )

#######################################
# find the most robust combination
#######################################

# find combinations that never gave TEs lower than limit
valid_combs = dta %>% 
  filter(fun=="mean" & proc == "NRST") %>% 
  group_by(mod,xps) %>% 
  summarise(n_valid_TE = sum(TE > TE_min)) %>% 
  ungroup() %>% 
  filter(n_valid_TE == max(n_valid_TE)) %>% 
  select(-n_valid_TE)

# print the combination that achieves the most consistent performance
summ=dta %>% 
  filter(fun == "mean" & proc == "NRST") %>% 
  inner_join(valid_combs) %>% 
  mutate(tgt = TE/costpar) %>%
  group_by(mod,xps) %>% 
  # compute aggregates over replications (seeds)
  summarise(agg_tgt = quantile(tgt,0.05)) %>% 
  ungroup() %>% 
  # group_by(mod) %>%
  # slice_max(agg_tgt,n=3)
  inner_join(
    (.) %>% 
      group_by(mod) %>%  
      slice_max(agg_tgt,n=1) %>% 
      select(max_agg_tgt=agg_tgt),
    by="mod") %>% 
  mutate(ratio = agg_tgt/max_agg_tgt) %>% 
  group_by(xps) %>% 
  summarise(mean_ratio=mean(ratio)) %>% 
  arrange(desc(mean_ratio))
summ # xps=0.01
