library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)

# search for csv files and process them
tsvs = list.files(pattern = '^NRSTExp_\\d+.tsv$')
fns  = substr(tsvs, 1, nchar(tsvs)-4)
dta  = data.frame()
for(i in seq_along(fns)){
  #i=1
  rawmeta     = read.delim(tsvs[i], header = FALSE)
  meta        = as.data.frame(t(rawmeta[,-1]))
  names(meta) = rawmeta[, 1]
  if(meta$exper == "ess_versus_cost"){
    newdta = read.csv(paste0(fns[i], ".csv.gz"))
    dta    = newdta %>%
      mutate(
        model = meta$model,
        maxcor= as.numeric(meta$maxcor)
      ) %>% 
      bind_rows(dta)
  }
}

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
             proc   = "IdealParallel",
             maxcor = 0)#,
    # jumpdta %>%
    #   filter(proc == "DTAct") %>%
    #   mutate(cost   = cstlen, # serial cost
    #          proc   = "I-Serial",
    #          maxcor = 0)   
    ) %>% 
    mutate(mcfac = factor(maxcor))
  
  plt = plotdta %>% 
    ggplot(aes(x = cost, y = cESS, color = mcfac, fill = mcfac, linetype = proc)) +
    # geom_point() +
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
    scale_linetype_discrete(name="Process") +
    # facet_wrap(~model, nrow = 1L) +
    theme_bw() + 
    theme(
      # text             = element_text(size = 10),
      # legend.margin    = margin(t=-5),
      panel.grid.minor = element_blank(),
      strip.background = element_blank(),
      plot.title       = element_text(face="bold", hjust = 0.5)
      # strip.text       = element_text(face = "bold")
    ) +
    labs(
      x = "Computational cost",
      y = "ESS bound @ cold level",
      title = mod
    )
  ggsave(sprintf("ess_versus_ipsteps_%s.pdf",mod), plot=plt, width=5, height=3.5)
}
