library(dplyr)
library(ggplot2)
library(scales)
library(stringr)
library(tidyr)

# search for csv files and process them
outdir = Sys.getenv("OUTDIR")
csvs = list.files(outdir, pattern = '.csv$')
dta = data.frame()
for(fn in csvs){
  newdta = read.csv(file.path(outdir,fn))
  sm = str_match(fn, '^E:(\\w+)_M:(\\w+)_MC:([.\\d]+)\\.csv$')
  dta = newdta %>%
    mutate(
      exper = sm[2],
      model = sm[3],
      maxcor= as.numeric(sm[4])
    ) %>% 
    bind_rows(dta)
}

#######################################
# ess_versus_cost: parallel
#######################################

pltdta = dta %>%
  filter(exper == "ess_versus_cost") %>% 
  select(-c(xs, exper)) %>% 
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
  facet_wrap(~model) +
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

