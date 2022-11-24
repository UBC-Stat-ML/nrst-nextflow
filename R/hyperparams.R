library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)

# load the latest consolidated file
csvs = list.files(path       = file.path("..","deliverables"),
                  pattern    = '^NRSTExp_\\d+.csv$',
                  full.names = TRUE)
dta  = read.csv(max(csvs))

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

##############################################################################
# find the most robust combination
##############################################################################

# find combinations that never gave TEs lower than limit
valid_combs = dta %>% 
  filter(fun=="mean" & proc == "NRST") %>% 
  group_by(mod,cor,gam) %>% 
  summarise(n_valid_TE = sum(TE > TE_min)) %>% 
  ungroup() %>% 
  filter(n_valid_TE == max(n_valid_TE)) %>% 
  select(-n_valid_TE)

# print the combination that achieves the most consistent performance
summ=dta %>% 
  filter(fun == "mean" & proc == "NRST") %>% 
  inner_join(valid_combs) %>% 
  mutate(tgt = TE/costpar) %>% 
  group_by(mod,cor,gam) %>% 
  # compute aggregates over replications (seeds)
  summarise(med_tgt = median(tgt),
            mmd_tgt = med_tgt/mad(tgt,center=med_tgt,constant = 1),
            msd_tgt = med_tgt/sd(tgt),
            mrn_tgt = med_tgt/diff(range(tgt)),
            mqt_tgt = med_tgt/(med_tgt - tgt[order(tgt)[2]]) # range discarding minimum and everything above median (don't care ab good surprises, only bad ones)
  ) %>% 
  ungroup() %>% 
  # group_by(mod) %>%
  # slice_max(mqt_tgt,n=3)
  inner_join(
    (.) %>% 
      group_by(mod) %>%  
      slice_max(mqt_tgt,n=1) %>% 
      select(max_mqt_tgt=mqt_tgt),
    by="mod") %>% 
  mutate(ratio = mqt_tgt/max_mqt_tgt) %>% 
  group_by(cor,gam) %>% 
  summarise(mean_ratio=mean(ratio)) %>% 
  arrange(desc(mean_ratio))
summ
