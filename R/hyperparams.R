source("utils.R")
library(gridExtra)

# load the latest consolidated file
csvs = sort(
  list.files(path       = file.path("..","deliverables"),
             pattern    = '^NRSTExp_hyperparams_\\d+.csv$',
             full.names = TRUE),
  decreasing=TRUE
)
dta  = read.csv(csvs[1])
n_reps = dta %>% 
  select(mod,seed) %>% 
  apply(2, n_distinct) %>% 
  prod

#######################################
# extract "valid combinations"; i.e., such that
#    1) all seeds must have finished without error
#    2) TEs higher than limit on all seeds
#    3) mean(xi) > xi_max, mean over seeds
#######################################

TE_min = 1e-4 # ntours(TE) truncates TE at this level, so configs with less than TE_min run less tours than they should
xi_max = 0.52 # wiggle room to .5 limit. note: xi is tail index for number of visits to top level. recall: for a>0, xi < a => E[Z^(1/a)] < infty
dta_is_valid = dta %>% 
  group_by(fun,cor,gam,xpl,xps,mod) %>%
  mutate(mean_xi = mean(xi, na.rm = TRUE), # NAs are due to runs that don't visit the top level
         is_valid = (TE >= TE_min & n_vis_top>0 & mean_xi <= xi_max)) %>%
  group_by(fun,cor,gam,xpl,xps) %>% 
  summarise(n_valid = sum(is_valid)) %>% 
  ungroup() %>%
  mutate(is_valid = n_valid == n_reps) %>% 
  select(-n_valid)

# filter combinations dominated by invalid combination according to cor
# intuition: lower cor bound should not make TE lower nor the tails of nvisits(N) heavier
valid_combs = dta_is_valid %>% 
  filter(is_valid) %>% 
  select(-is_valid) %>% 
  left_join(
    dta_is_valid %>% 
      filter(!is_valid) 
  , by = c("fun","gam","xpl","xps")) %>% 
  mutate(dominated_by_invalid = cor.x < 1 & !is.na(cor.y) & (cor.y < cor.x) & !is_valid) %>% 
  filter(!dominated_by_invalid) %>% 
  rename(cor=cor.x) %>% 
  select(-cor.y, -is_valid, -dominated_by_invalid) %>% 
  unique()

#######################################
# find the most robust combination:
# 1) For each (valid) combination, get quantile of cost_var across repetitions
# 2) For each model, find the minimal cost; i.e., cost associated with the config optimal for this model
# 3) For each model-combination, compute cost_ratio = cost/min(cost)
# 4) For each combination, compute max(cost_ratio) across models
# 5) Select combination with lowest max(cost_ratio)
#######################################

cost_var = quote(costser)
q_tgt    = 1.0

# compute cost for each mod x config combination, find best config for each mod
dta_agg_tgt=dta %>% 
  inner_join(valid_combs) %>% 
  mutate(tgt = eval(cost_var)) %>%
  group_by(mod,fun,cor,gam,xpl,xps) %>% 
  # compute aggregates over replications (seeds)
  summarise(agg_tgt = quantile(tgt,q_tgt)) %>% 
  ungroup() %>%
  inner_join(
    (.) %>% 
      group_by(mod) %>%  
      slice_min(agg_tgt,n=1,with_ties=FALSE) %>% 
      select(min_agg_tgt=agg_tgt),
    by="mod"
  ) %>% 
  mutate(regret = agg_tgt-min_agg_tgt) #%>% # using abs diff prioritizes harder models. ratio normalizes them
  # group_by(mod) %>% slice_min(agg_tgt,n=3) %>% print(n=Inf)
  
# select the config with least regret
summ = dta_agg_tgt %>% 
  group_by(fun,cor,gam,xpl,xps) %>% 
  summarise(agg_regret=max(regret),
            nmods = n()) %>% 
  arrange(agg_regret) %>% print

# inspect config
summ[1,] %>% inner_join(dta_agg_tgt) %>% arrange(desc(regret))

##############################################################################
# plot: all correlations for fixed else
##############################################################################

dta_agg_tgt %>% 
  filter(gam== 3 & fun == "mean") %>% 
  ggplot(aes(x = as.factor(cor), y = agg_tgt/min_agg_tgt)) +
  geom_point() +
  facet_wrap(~mod, labeller = labellers) +
  theme_bw() +
  theme(
    legend.position = "bottom",
    legend.margin    = margin(t=-5),
  )+
  labs(
    x = "Correlation bound (<1) or Number of fixed expl. steps (>=1)",
    y = cost_var_label(cost_var)
  )

##############################################################################
# plot: distribution of target measure for all combinations and models
##############################################################################

# note: fixes xpl and xps
dta %>% 
  filter(xpl==summ$xpl[1] & xps==summ$xps[1]) %>% 
  inner_join(valid_combs) %>%
  ggplot(aes(x = as.factor(cor), y = eval(cost_var), color = fun)) +
  geom_boxplot() +
  scale_y_log10(
    breaks = log10_breaks,
    labels = scales::trans_format("log10", scales::label_math(format=function(x){sprintf("%.1f",x)}))
  ) +
  scale_color_discrete(name="Strategy",
                       labels=c("mean"="Mean", "median"="Median")) +
  facet_grid(mod~gam, labeller = labellers, scales="free") +
  theme_bw() +
  theme(
    legend.position = "bottom",
    legend.margin    = margin(t=-5),
    )+
  labs(
    x = "Correlation bound (<1) or Number of fixed expl. steps (>=1)",
    y = cost_var_label(cost_var)
  )
ggsave("hyperparams_all.pdf", width=6, height = 6, device = cairo_pdf) # device needed on Linux to print unicode correctly

##############################################################################
# correlation costset v. costpar: very uncorrelated within a combination
##############################################################################

mods  = unique(dta$mod)
plist = vector("list",length(mods))
for(i in seq_along(plist)){
  # i=1
  plist[[i]] = dta %>% 
    filter(mod == mods[i] & xps == 0.1 & fun == "median") %>% 
    inner_join(valid_combs) %>% 
    ggplot(aes(x = costser, y = costpar)) +
    geom_point() +
    scale_x_log10() +
    scale_y_log10() +
    scale_color_discrete(name="Strategy",
                         labels=c("mean"="Mean", "median"="Median")) +
    facet_grid(gam ~ cor, labeller = labellers, scales="free") +
    theme_bw() +
    # {if(i<length(mods)) {theme(legend.position = "none")}} +
    labs(
      x = "Correlation bound",
      y = "max(total exploration steps)",
      title=mods[i]
    )
}
grid.arrange(grobs=plist,nrow=1)

##############################################################################
# summarizing (gam,cor,xps) with unique measure of total nexpls in perfect run
# TODO: replace estimator with proper nexpls when they are available
##############################################################################

# bin total nexpls
nexps_dta = dta %>%
  group_by(mod, cor, gam, xps) %>% 
  summarise(nexpls = mean(N*costser/rtser)) %>% # TODO: replace with actual data
  group_by(mod) %>% 
  mutate(nxps_bin = cut(nexpls,breaks = 5)) %>% 
  ungroup

plist = vector("list",length(mods))
for(i in seq_along(plist)){
  plist[[i]] = dta %>% 
    filter(xps == 0.01 & mod == mods[i]) %>% 
    inner_join(nexps_dta) %>% 
    ggplot(aes(x = N, y = TE/costpar)) +
    geom_point() +
    facet_wrap(~ nxps_bin,ncol=1, labeller = labellers, scales="free_y") +
    theme_bw() +
    labs(
      x = "Size of the grid",
      y = "TE/max(number of V(x) evals.)",
      title=mods[i]
    )
}
grid.arrange(grobs=plist,nrow=1)

