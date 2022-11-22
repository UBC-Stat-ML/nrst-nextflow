library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)

# load the latest consolidated file
csvs = list.files(path       = file.path("..","deliverables"),
                  pattern    = '^NRSTExp_\\d+.csv$',
                  full.names = TRUE)
dta  = read.csv(max(csvs))

##############################################################################
# TE/max V evals
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

# print the combination that achieves the most consistent performance
summ=dta %>% 
  filter(proc == "NRST" & TE >= 5e-4) %>% # update with NRST.DEFAULT_TE_min
  mutate(tgt = TE/costpar) %>% 
  group_by(mod,cor,gam) %>% 
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
##############################################################################
# compare parallel for different correlations
##############################################################################

# return data at jump times of a given column
dtaatjumps = function(df, colname){
  list(df[c(TRUE,diff(df[,colname,drop=TRUE]) > 0),])
}

#######################################
# case 1: cost = num of index process steps
#######################################

ltys = c("NRST" = "solid", "Ideal" = "dotdash")

# filter jumps
jumpdta = dta %>% 
  nest_by(proc, rep, model, maxcor) %>% 
  mutate(jumpdta = dtaatjumps(data, "cmtlen")) %>% 
  select(-data) %>% 
  unnest(jumpdta) %>% 
  ungroup()

# iterate models
for(mod in unique(jumpdta$model)){
  # mod="Challenger"
  moddta = filter(jumpdta, model == mod)
  
  # plot NRST + serial and parallel DTAct
  plotdta = bind_rows(
    moddta %>% 
      filter(proc == "NRST") %>%  # add all NRST results
      mutate(cost = cmtlen),
    moddta %>%
      filter(proc == "DTAct") %>%
      mutate(cost   = cmtlen, # parallel cost
             proc   = "Ideal",
             maxcor = 0)
    # jumpdta %>%
    #   filter(proc == "DTAct") %>%
    #   mutate(cost   = cstlen, # serial cost
    #          proc   = "IdealSer",
    #          maxcor = 0)
  ) %>%
    mutate(mcfac = factor(maxcor))
  plt = plotdta %>% 
    ggplot(aes(x = cost, y = cESS, color = mcfac, fill = mcfac, linetype = proc)) +
    geom_smooth() +
    scale_x_log10(
      breaks = scales::trans_breaks("log10", function(x) 10^x, high.u.bias = 3), # discourage fractional powers
      labels = scales::trans_format("log10", scales::math_format(10^.x))
    ) +
    scale_y_log10(
      breaks = scales::trans_breaks("log10", function(x) 10^x),
      labels = scales::trans_format("log10", scales::math_format(10^.x))
    ) +
    scale_colour_viridis_d(name="Max. Corr.") +
    scale_fill_viridis_d(name="Max. Corr.") +
    scale_linetype_manual(name="Process", values = ltys) +
    theme_bw() + 
    theme(
      panel.grid.minor = element_blank(),
      strip.background = element_blank(),
      plot.title       = element_text(face="bold", hjust = 0.5)
    ) +
    labs(
      x = "Number of index process steps",
      y = "ESS bound @ cold level",
      title = mod
    )
  ggsave(sprintf("ess_v_ipsteps_%s.pdf",mod), plot=plt, width=5, height=3.5)
}

#######################################
# case 2: cost = num of V evaluations
#######################################

# filter jumps
jumpdta = dta %>% 
  filter(proc == "NRST") %>% 
  select(-proc) %>% 
  nest_by(rep, model, maxcor) %>% 
  mutate(jumpdta = dtaatjumps(data, "cmnvev")) %>% 
  select(-data) %>% 
  unnest(jumpdta) %>% 
  ungroup()

# iterate models
for(mod in unique(jumpdta$model)){
  # mod="Challenger"
  plt = jumpdta %>% 
    filter(model == mod) %>% 
    mutate(mcfac = factor(maxcor)) %>% 
    ggplot(aes(x = cmnvev, y = cESS, color = mcfac, fill = mcfac)) +
    geom_smooth() +
    scale_x_log10(
      breaks = scales::trans_breaks("log10", function(x) 10^x, high.u.bias = 3), # discourage fractional powers
      labels = scales::trans_format("log10", scales::math_format(10^.x))
    ) +
    scale_y_log10(
      breaks = scales::trans_breaks("log10", function(x) 10^x),
      labels = scales::trans_format("log10", scales::math_format(10^.x))
    ) +
    scale_colour_viridis_d(name="Max. Corr.") +
    scale_fill_viridis_d(name="Max. Corr.") +
    theme_bw() + 
    theme(
      panel.grid.minor = element_blank(),
      strip.background = element_blank(),
      plot.title       = element_text(face="bold", hjust = 0.5)
    ) +
    labs(
      x = "Number of evaluations of the potential",
      y = "ESS bound @ cold level",
      title = mod
    )
  ggsave(sprintf("ess_v_nvevs_%s.pdf",mod), plot=plt, width=5, height=3.5)
}
