library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)

# search for csv files and process them
tsvs = list.files(pattern = '^NRSTExp_\\d+.tsv$')
cat("Found metadata:\n"); print(tsvs)
fns  = substr(tsvs, 1, nchar(tsvs)-4)
dta  = data.frame()
for(i in seq_along(fns)){
  #i=1
  rawmeta     = read.delim(tsvs[i], header = FALSE)
  cat("debug\n");print(rawmeta)
  meta        = as.data.frame(t(rawmeta[,-1]))
  cat("debug\n");print(names(meta))
  cat("debug\n");print(rawmeta[, 1])
  names(meta) = rawmeta[, 1]
  if(meta$exper == "ess_versus_cost"){
    newdta = read.csv(paste0(fns[i], ".csv"))
    dta    = newdta %>%
      mutate(
        model = meta$model,
        maxcor= as.numeric(meta$maxcor)
      ) %>% 
      bind_rows(dta)
  }
}

#######################################
# ess_versus_cost: parallel
#######################################

pltdta = dta %>%
  select(-xs) %>% 
  rename(cost=xp,ess=y)
pltdta = bind_rows(
  pltdta %>% filter(proc=="NRST"),
  pltdta %>% filter(proc=="DTAct") %>% mutate(maxcor=0.)
  ) %>% 
  select(-proc) %>% 
  mutate(mcfac = factor(maxcor))
plt = pltdta %>% 
  ggplot(aes(x = cost, y = ess, color = mcfac, fill = mcfac)) +
  geom_smooth() +
  scale_x_continuous(labels = math_format())+
  scale_y_continuous(labels = math_format())+
  scale_colour_viridis_d(name="Max. Corr.") +
  scale_fill_viridis_d(name="Max. Corr.") +
  facet_wrap(~model, nrow = 1L) +
  theme_bw() + 
  theme(
    # text             = element_text(size = 10),
    # legend.margin    = margin(t=-5),
    panel.grid.minor = element_blank(),
    strip.background = element_blank(),
    strip.text       = element_text(face = "bold")
  ) +
  labs(
    x = "Computational cost",
    y = "ESS bound @ cold level"
  )
ggsave("ess_versus_cost.pdf", plot=plt, width=5*length(unique(pltdta$model)), height=3.5)

