source("utils.R")
library(gridExtra)

# load the latest consolidated file
csvs = sort(
  list.files(path       = file.path("..","deliverables"),
             pattern    = '^NRSTExp_TE_ELE_\\d+.csv$',
             full.names = TRUE),
  decreasing=TRUE
)
dta  = read.csv(csvs[1])

##############################################################################
# for each model, get best estimate of TE_ELE
##############################################################################

TE_ELEs = dta %>% 
  filter(cor == min(cor) & gam == max(gam)) %>% 
  group_by(mod) %>% 
  summarise(TE_ELE = mean(1/(1+2*Lambda))) %>% 
  ungroup

##############################################################################
# plot TE versus gam and cor
##############################################################################

# cor
pcor = dta %>%
  filter(gam == max(gam)) %>% 
  inner_join(TE_ELEs, by="mod") %>%
  mutate(fcor = factor(cor,levels=sort(unique(cor),decreasing = TRUE))) %>% 
  ggplot(aes(x = fcor, y = TE)) +
  geom_boxplot() +
  geom_hline(aes(yintercept=TE_ELE), linetype="dashed")+
  facet_wrap(~mod, labeller = labellers, scales = "free_y", ncol=1) +
  theme_bw() +
  theme(
    legend.position = "bottom",
    legend.margin    = margin(t=-5),
  )+
  labs(
    x = paste0("Correlation bound (grid size ≈ ", 2*max(dta$gam),"Λ)"),
    y = "Tour Effectiveness"
  )

# gam
pgam = dta %>%
  filter(cor == min(cor)) %>% 
  inner_join(TE_ELEs,by="mod") %>% 
  ggplot(aes(x = as.factor(gam), y = TE)) +
  geom_boxplot() +
  geom_hline(aes(yintercept=TE_ELE), linetype="dashed")+
  facet_wrap(~mod, labeller = labellers, scales = "free_y", ncol=1) +
  theme_bw() +
  theme(
    legend.position = "bottom",
    legend.margin    = margin(t=-5),
  )+
  labs(
    x = paste0("Grid size / 2Λ (correlation ≤ ", min(dta$cor),")"),
    y = "Tour Effectiveness"
  )
pboth = grid.arrange(pcor,pgam,ncol=2)
ggsave("TE_ELE.pdf", pboth,width=6, height = 4, device = cairo_pdf) # device needed on Linux to print unicode correctly
