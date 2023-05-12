source("utils.R")

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
xi_max = 0.70 # wiggle room to .5 limit. note: xi is GPD tail index for number of visits to top level. recall: for a>0, xi < a => E[Z^(1/a)] < infty
dta_mean_xi = dta %>% 
  group_by(fun,cor,gam,xpl,xps,mod) %>%
  summarize(mean_xi = mean(xi, na.rm = TRUE),  # NAs are due to runs that don't visit the top level
            min_TE = min(TE),
            nreps = n()) %>% 
  ungroup
dta_is_valid = dta %>% 
  inner_join(dta_mean_xi) %>%
  mutate(is_valid = (TE >= TE_min & n_vis_top>0 & mean_xi <= xi_max)) %>%
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
gen_dta_agg_tgt = function(cvar){
  dta %>% 
    inner_join(valid_combs) %>% 
    mutate(tgt = eval(cvar)) %>%
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
    mutate(regret_abs = agg_tgt-min_agg_tgt, # using abs diff prioritizes harder models
           regret_rat = agg_tgt/min_agg_tgt) # using ratio normalizes them
}

# compute regrets
dta_agg_tgt = gen_dta_agg_tgt(cost_var)

# inspect 3 best configs per model
dta_agg_tgt %>%  group_by(mod) %>% slice_min(agg_tgt,n=3) %>% print(n=Inf)

# select the config with least regret
summ = dta_agg_tgt %>% 
  group_by(fun,cor,gam,xpl,xps) %>% 
  summarise(agg_regret=max(regret_abs),
            nmods = n()) %>% 
  arrange(agg_regret) %>% print

# inspect config
summ[1,] %>% inner_join(dta_agg_tgt) %>% arrange(desc(regret_abs))

##############################################################################
# plot: gam, fix everything else
##############################################################################

dta %>% 
  inner_join(summ[1,c("fun", "cor")], by=c("fun", "cor") ) %>%
  ggplot(aes(x = as.factor(gam), y = eval(cost_var))) +
  geom_boxplot(lwd=0.25) +
  # geom_line(
  #   data = inner_join(dta_agg_tgt,summ[1,c("fun", "cor")], by=c("fun", "cor") ),
  #   aes(x = gam, y = agg_tgt),
  #   linetype = "dotted"
  # ) +
  my_scale_y_log10() +
  facet_wrap(~mod, labeller = labellers, scales="free_y") +
  my_theme() +
  labs(
    x = "Gamma correction",
    y = cost_var_label(cost_var)
  )

ggsave("hyperparams_gam.pdf", width=6, height = 3, device = cairo_pdf) # device needed on Linux to print unicode correctly

##############################################################################
# plot: cor, fix everything else
##############################################################################

dta %>% 
  filter(cor>=0.8) %>% # can't fit more
  inner_join(valid_combs) %>%
  inner_join(summ[1,c("fun", "gam")], by=c("fun", "gam") ) %>%
  mutate(is_fixed = ifelse(cor>=1,"Fixed","Tuned"),
         fcor = format_cors(cor)) %>% 
  ggplot(aes(x = fcor, y = eval(cost_var), color=is_fixed)) +
  geom_boxplot(lwd=0.25, show.legend=FALSE) +
  scale_color_manual(name="Exploration steps",values=c("blue", "black"))+
  my_scale_y_log10() +
  facet_wrap(~mod, labeller = labellers, scales="free_y") +
  my_theme() +
  labs(
    x = "Maximum allowed autocorrelation",
    y = cost_var_label(cost_var)
  )

ggsave("hyperparams_cor.pdf", width=6, height = 3)

##############################################################################
# plot: fun, fix everything else.
# problem: the best mean (cor,gam) combination might be invalid for median
# need to find one that exists for both
##############################################################################

# compute regrets, select the config with least regret
cost_var_other = ifelse(cost_var==quote(costser),quote(costpar),quote(costser))
summ_other = gen_dta_agg_tgt(cost_var_other) %>% 
  group_by(fun,cor,gam,xpl,xps) %>% 
  summarise(agg_regret=max(regret_abs),
            nmods = n()) %>% 
  arrange(agg_regret)

make_fun_plot = function(plot_cost_var,bottom=FALSE){
  cost_var_name_short = ifelse(plot_cost_var==quote(costser),"Serial","Parallel")
  dta %>% 
    inner_join(valid_combs) %>%
    inner_join(
      bind_rows(summ[1,],summ_other[1,])[,c("fun", "cor", "gam")],
      by=c("fun", "cor", "gam") ) %>%
    ggplot(aes(x = fun, y = eval(plot_cost_var))) +
    geom_boxplot(width=0.5,lwd=0.25) +
    scale_x_discrete(labels = c("mean"="Mean","median"="Med")) +
    my_scale_y_log10(digits=0) +
    coord_flip()+
    facet_grid(
      eval(cost_var_name_short)~mod, 
      labeller = labeller(mod=mod_short_label), 
      scales="free_x"
    )+
    theme_bw() +
    my_theme() +
    {if(bottom){
      theme(strip.text.x = element_blank(),
            plot.margin = margin(0, 0, 0, 0, "pt"))
    }else{
      theme(axis.title.x = element_blank(),
            plot.margin = margin(0, 0, 5.5, 0, "pt"))
    }}+
    theme(axis.title.y = element_blank()) +
    labs(y="Cost")
}
p1 = make_fun_plot(cost_var)
p2 = make_fun_plot(cost_var_other,TRUE)
prop_p1 = 0.53
p=plot_grid(p1, p2, align = "v", nrow=2,rel_heights = c(prop_p1, 1-prop_p1))
ggsave("hyperparams_fun.pdf", p, width=6, height = 2.5)

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
  facet_grid(mod~gam, labeller = labellers, scales="free", s) +
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

