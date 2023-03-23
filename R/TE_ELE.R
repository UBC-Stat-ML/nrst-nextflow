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
dta %>%
  filter(gam == max(gam)) %>% 
  inner_join(TE_ELEs, by="mod") %>%
  mutate(fcor = factor(cor,levels=sort(unique(cor),decreasing = TRUE))) %>% 
  ggplot(aes(x = fcor, y = TE)) +
  geom_boxplot() +
  geom_hline(aes(yintercept=TE_ELE), linetype="dashed")+
  facet_wrap(~mod, labeller = labellers, scales="free") +
  theme_bw() +
  theme(
    legend.position = "bottom",
    legend.margin    = margin(t=-5),
  )+
  labs(
    x = "Correlation bound (<1) or Number of fixed expl. steps (>=1)",
    y = "Tour Effectiveness"
  )

# gam
dta %>%
  filter(cor == min(cor)) %>% 
  inner_join(TE_ELEs,by="mod") %>% 
  ggplot(aes(x = as.factor(gam), y = TE)) +
  geom_boxplot() +
  geom_hline(aes(yintercept=TE_ELE), linetype="dashed")+
  facet_wrap(~mod, labeller = labellers, nrow=1) +
  theme_bw() +
  theme(
    legend.position = "bottom",
    legend.margin    = margin(t=-5),
  )+
  labs(
    x = "γ (grid size ≈ 2γΛ)",
    y = "Tour Effectiveness"
  )
# ggsave("TE_ELE.pdf", width=6, height = 6, device = cairo_pdf) # device needed on Linux to print unicode correctly
