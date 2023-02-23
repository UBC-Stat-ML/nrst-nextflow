library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)
library(gridExtra)

# load the latest consolidated file
csvs = sort(
  list.files(path       = file.path("..","deliverables"),
             pattern    = '^NRSTExp_hyperparams_\\d+.csv$',
             full.names = TRUE),
  decreasing=TRUE
)
dta  = read.csv(csvs[1])#csvs[1]
nreps = n_distinct(dta$seed)

# labellers
cost_var_label = function(s){
  paste0(ifelse(s == quote(costpar),"Max","Sum"),"(exploration steps)")
}
labellers = labeller(
  cor = function(co){paste("Max. Corr. =", co)},
  gam = function(ga){paste0("γ = ",ga," (N ≈ ", 2*as.integer(ga),"Λ)")},
  xps = function(xp){paste0("Smooth window ≈ ", xp,"N")},
  nxps_bin = function(b){paste("Straight-line cost ∈",b)}
)

#######################################
# extract "valid combinations"
#######################################

# find combinations that, across 30 reps, *never* gave 1) TEs lower than limit 
# and 2) xi > xi_max.
# can be thought of asking for 1-1/30 ~ 97% prob that for any model and seed,
# the config will have these nice properties
TE_min = 1e-4 # currently no experiment below this. Note: ntours(TE) truncates TE at this level, so configs with less than TE_min run less tours than they should
xi_max = 0.50 # for a>0, xi < a => E[Z^(1/a)] < infty
cost_var = quote(costser)

valid_combs = dta %>% 
  mutate(is_valid = (TE > TE_min & xi < xi_max)) %>%
  group_by(fun,cor,gam,xps) %>% 
  summarise(n_valid_TE = sum(is_valid)) %>% 
  ungroup() %>% 
  # arrange(n_valid_TE) %>% 
  filter(n_valid_TE == max(n_valid_TE)) %>% 
  select(-n_valid_TE)

##############################################################################
# plot: distribution of target measure for all combinations and models
##############################################################################

# mods  = unique(dta$mod)
# plist = vector("list",length(mods))
# for(i in seq_along(plist)){
#   plist[[i]] = dta %>% 
#     filter(mod == mods[i]) %>% 
#     inner_join(valid_combs) %>% 
#     ggplot(aes(x = as.factor(cor), y = costpar, color = fun)) +
#     geom_boxplot() +
#     scale_color_discrete(name="Strategy",
#                          labels=c("mean"="Mean", "median"="Median")) +
#     facet_grid(gam ~ xps, labeller = labellers, scales="free") +
#     theme_bw() +
#     {if(i<length(mods)) {theme(legend.position = "none")}} +
#     labs(
#       x = "Correlation bound",
#       y = "max(total exploration steps)",
#       title=mods[i]
#     )
# }
# grid.arrange(grobs=plist,nrow=1)

# similar but simpler by filtering on xps
dta %>% 
  filter(xps==min(dta$xps)) %>% 
  inner_join(valid_combs) %>% 
  ggplot(aes(x = as.factor(cor), y = eval(cost_var), color = fun)) +
  geom_boxplot() +
  scale_color_discrete(name="Strategy",
                       labels=c("mean"="Mean", "median"="Median")) +
  facet_grid(mod~gam, labeller = labellers, scales="free") +
  theme_bw() +
  labs(
    x = "Correlation bound",
    y = cost_var_label(cost_var)
  )

#######################################
# find the most robust combination:
# 1) For each (valid) combination, get quantile of cost_var across repetitions
# 2) For each model, find the minimal cost; i.e., cost associated with the config optimal for this model
# 3) For each model-combination, compute cost_ratio = cost/min(cost)
# 4) For each combination, compute max(cost_ratio) across models
# 5) Select combination with lowest max(cost_ratio)
#######################################

q_tgt = 1.0
summ=dta %>% 
  # filter(mod != "HierarchicalModel") %>%
  inner_join(valid_combs) %>% 
  mutate(tgt = eval(cost_var)) %>%
  group_by(mod,fun,cor,gam,xps) %>% 
  # compute aggregates over replications (seeds)
  summarise(agg_tgt = quantile(tgt,q_tgt)) %>% 
  ungroup() %>% 
  # group_by(mod) %>%
  # slice_min(agg_tgt,n=3)
  inner_join(
    (.) %>% 
      group_by(mod) %>%  
      slice_min(agg_tgt,n=1) %>% 
      select(min_agg_tgt=agg_tgt),
    by="mod") %>% 
  mutate(regret = agg_tgt-min_agg_tgt) %>% # using abs diff prioritizes harder models. ratio would equalize them
  group_by(fun,cor,gam,xps) %>% 
  summarise(max_regret=max(regret),
            nmods = n()) %>% 
  arrange(max_regret)
summ

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
