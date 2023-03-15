library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)

# labellers
cost_var_label = function(s){
  paste0(ifelse(s == quote(costpar),"Max","Sum"),"(number of V evaluations)")
}
labellers = labeller(
  cor = function(co){paste("Max. Corr. =", co)},
  gam = function(ga){paste0("γ = ",ga," (N ≈ ", 2*as.integer(ga),"Λ)")},
  xps = function(xp){paste0("Smooth window ≈ ", xp,"N")},
  nxps_bin = function(b){paste("Straight-line cost ∈",b)}
)
log10_breaks=function(x) {
  y=log10(x)
  # n=min(5L,2+ceiling(diff(range(y))))
  10^(pretty(y, 4, 2))
}
