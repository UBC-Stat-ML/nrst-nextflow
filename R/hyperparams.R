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

# parameters
TE_min = 1e-6

##############################################################################
# plot: TE/(max V evals) for all combinations and models
##############################################################################

labellers = labeller(
  cor = function(co){paste("Max. Corr. =", co)},
  gam = function(ga){paste0("γ = ",ga," (N ≈ ", 2*as.integer(ga),"Λ)")},
  xps = function(xp){paste("Smooth window ≈", xp,"N")},
  nxps_bin = function(b){paste("Straight-line cost ∈",b)}
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
  facet_grid(gam ~ mod, labeller = labellers, scales="free_x") +
  theme_bw() +
  labs(
    x = "Efficiency = TE/max(number of V(x) evals.)",
    y = "Maximum correlation"
  )

##############################################################################
# another way of visualizing the same
##############################################################################

mods  = unique(dta$mod)
plist = vector("list",length(mods))
for(i in seq_along(plist)){
  plist[[i]] = dta %>% 
    filter(mod == mods[i]) %>% 
    ggplot(aes(x = as.factor(cor), y = costpar)) +
    geom_boxplot() +
    facet_grid(gam ~ xps, labeller = labellers)+#, scales="free_x") +
    theme_bw() +
    labs(
      x = "Maximum correlation",
      y = "TE/max(number of V(x) evals.)",
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

#######################################
# find the most robust combination:
# maximize the p5 across repetitions
#######################################

q_tgt = .25#3/nreps # find combination that maximizes the q_tgt quantile across reps.

# find combinations that never gave TEs lower than limit
valid_combs = dta %>% 
  group_by(fun,cor,gam,xps) %>% 
  summarise(n_valid_TE = sum(TE > TE_min)) %>% 
  ungroup() %>% 
  arrange(n_valid_TE) %>% 
  filter(n_valid_TE == max(n_valid_TE)) %>% 
  select(-n_valid_TE)

summ=dta %>% 
  # filter(mod != "HierarchicalModel") %>% 
  inner_join(valid_combs) %>% 
  mutate(tgt = 1/costpar) %>%
  group_by(mod,fun,cor,gam,xps) %>% 
  # compute aggregates over replications (seeds)
  summarise(agg_tgt = quantile(tgt,q_tgt)) %>% 
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
  group_by(fun,cor,gam,xps) %>% 
  summarise(mean_ratio=mean(ratio)) %>% 
  arrange(desc(mean_ratio))
summ


dta %>% 
  filter(TE<=0.1) %>% 
  ggplot(aes(x=TE,y=xi,color=fun))+
  geom_point()+
  facet_wrap(~mod)

xidta = dta %>%
  filter(mod=="MRNATrans",xps==0.1) %>% 
  group_by(fun,cor,gam) %>% 
  summarise(xi=mean(xi)) %>% 
  ungroup() %>% 
  arrange(xi)
