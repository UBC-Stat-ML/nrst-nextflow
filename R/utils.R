library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)
library(cowplot)

# labellers
cost_var_label = function(s){
  paste0(ifelse(
    s == quote(costpar),
    "Maximum",
    "Total"
  )," number of V evaluations")
}
mod_short_label = c(
  "Banana"="Banana",
  "Funnel"="Funnel",
  "HierarchicalModel"="HierarchModel",
  "MRNATrans"="MRNATrans",
  "ThresholdWeibull"="ThreshWeibull", 
  "XYModel"="XYModel"
)
labellers = labeller(
  cor = function(co){paste("Max. Corr. =", co)},
  gam = function(ga){paste0("γ = ",ga," (N ≈ ", round(2*as.double(ga)),"Λ)")},
  xps = function(xp){paste0("Smooth window ≈ ", xp,"N")},
  nxps_bin = function(b){paste("Straight-line cost ∈",b)},
  cost_var = cost_var_label
)
# insane but it works: ask for many breaks, just use 2 in the interior
log10_breaks=function(x){
  lx=log10(x)
  p=pretty(lx,8,8)
  10^c(p[3],p[length(p)-2])
}
# impossible to get x.y10^z notation consistently. ggplot2 will not print y
# when y=0!!!!
gen_log10_labels=function(digits=1){
  fstr = paste0("%.",digits,"fe%d")
  function(x){
    e = floor(log10(x))
    m = x*10^-e
    s = sprintf(fstr,m,e)
    s
  }
}
my_scale_y_log10 = function(digits=1){
  scale_y_log10(breaks=log10_breaks,labels=gen_log10_labels(digits))
}

# theme
my_theme = function(){
  theme_bw() +
    theme(
      legend.position = "bottom",
      legend.margin    = margin(t=-5),
      strip.background = element_blank()
    )
}

# format correlations
format_cors = function(cor,...){
  cor_levels = sort(unique(cor), ...)
  cor_labels = sprintf(ifelse(cor_levels >= 1, "Fix", ".%d"),as.integer(round(100*cor_levels)))
  factor(cor,cor_levels,labels=cor_labels,ordered=TRUE)
}
