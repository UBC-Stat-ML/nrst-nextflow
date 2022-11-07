library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)

# load the latest consolidated file
csvs = list.files(pattern = '^NRSTExp_\\d+.csv$')
dta  = read.csv(max(csvs))

# filter out mvnormal experiment due to error in tuning always with free energy
# TODO: remove once above is corrected
dta = filter(dta, mod != "MvNormal")

##############################################################################
# compare mean / median
##############################################################################

cor_gam_labs = labeller(
  cor = function(co){paste("Max. Corr. =", co)},
  gam = function(ga){paste0("γ = ",ga," (N ≈ ", 2*as.integer(ga),"Λ)")}
)

# TE
dta %>% 
  filter(proc == "NRST") %>% 
  ggplot(aes(y = mod, x = TE, color = fun)) +
  geom_violin() +
  scale_x_log10() +
  facet_grid(cor ~ gam, labeller = cor_gam_labs) + 
  theme_bw() +
  labs(
    x = "Tour Effectiveness (TE)",
    y = "Model"
  )

# TE/max tour length
dta %>% 
  filter(proc == "NRST") %>% 
  mutate(tgt = TE/rtpar) %>% 
  ggplot(aes(y = mod, x = tgt, color = fun)) +
  geom_violin() +
  scale_x_log10() +
  facet_grid(cor ~ gam, labeller = cor_gam_labs) + 
  theme_bw() +
  labs(
    x = "Efficiency = TE/max(tourlength)",
    y = "Model"
  )

# TE/max V evals
dta %>% 
  filter(proc == "NRST") %>% 
  mutate(tgt = TE/costpar) %>% 
  ggplot(aes(y = mod, x = tgt, color = fun)) +
  geom_violin() +
  scale_x_log10() +
  facet_grid(cor ~ gam, labeller = cor_gam_labs) +
  theme_bw() +
  labs(
    x = "Efficiency = TE/max(number of V(x) evals.)",
    y = "Model"
  )

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
