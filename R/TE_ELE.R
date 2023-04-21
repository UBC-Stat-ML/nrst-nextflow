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
  filter(gam == max(gam) & cor != 0.75) %>% 
  inner_join(TE_ELEs, by="mod") %>%
  mutate(fcor = factor(cor,levels=sort(unique(cor),decreasing = TRUE))) %>% 
  ggplot(aes(x = fcor, y = TE)) +
  geom_boxplot() +
  geom_hline(aes(yintercept=TE_ELE), linetype="dashed")+
  scale_y_continuous(limits=c(0,NA))+
  facet_wrap(~mod, labeller = labellers,nrow=1)+#, scales = "free_y") +
  theme_bw() +
  theme(
    legend.position = "bottom",
    legend.margin    = margin(t=-5),
  )+
  labs(
    x = paste0("Maximum allowed correlation (grid size ≈ ", 2*max(dta$gam),"Λ)"),
    y = "Tour Effectiveness"
  )
ggsave("TE_ELE_cor.pdf", pcor,width=6, height = 2, device = cairo_pdf) # device needed on Linux to print unicode correctly

# gam
pgam = dta %>%
  filter(cor == min(cor)) %>% 
  inner_join(TE_ELEs,by="mod") %>% 
  ggplot(aes(x = as.factor(gam), y = TE)) +
  geom_boxplot() +
  geom_hline(aes(yintercept=TE_ELE), linetype="dashed")+
  facet_wrap(~mod, labeller = labellers,nrow=1)+#, scales = "free_y") +
  theme_bw() +
  theme(
    legend.position = "bottom",
    legend.margin    = margin(t=-5),
  )+
  labs(
    x = paste0("Grid size / 2Λ (max. correlation ≤ ", min(dta$cor),")"),
    y = "Tour Effectiveness"
  )
ggsave("TE_ELE_gam.pdf", pgam,width=6, height = 2, device = cairo_pdf) # device needed on Linux to print unicode correctly
