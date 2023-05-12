source("utils.R")

# load the latest consolidated file
csvs = sort(
  list.files(path       = file.path("..","deliverables"),
             pattern    = '^NRSTExp_TE_ELE_\\d+.csv$',
             full.names = TRUE),
  decreasing=TRUE
)
dta  = read.csv(csvs[1])

##############################################################################
# for each model, get best estimate of TE_ELE, which occurs for the lowest
# correlation and highest gam
##############################################################################

TE_ELEs = dta %>% 
  filter(cor == min(cor) & gam == max(gam)) %>% 
  group_by(mod) %>% 
  summarise(TE_ELE = mean(1/(1+2*Lambda))) %>% 
  ungroup

##############################################################################
# plot TE versus gam and cor
##############################################################################

dta %>% 
  mutate(fcor = format_cors(cor),#,decreasing=TRUE),
         fgam = as.factor(gam)) %>%
  group_by(fcor,fgam,mod) %>%
  summarise(mean_TE = mean(TE)) %>% 
  ungroup() %>% 
  inner_join(TE_ELEs, by="mod") %>%
  mutate(TE_ratio = mean_TE/TE_ELE) %>% 
  ggplot(aes(x=fcor, y=fgam, fill=TE_ratio)) + 
  geom_tile() +
  scale_x_discrete(expand = c(0,0)) +
  scale_y_discrete(expand = c(0,0)) +
  scale_fill_continuous(type = "viridis") +
  facet_wrap(~mod, labeller = labellers,nrow=2)+#, scales = "free_y") +
  my_theme() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), legend.position = "right") +
  labs(
    x = "Maximum allowed autocorrelation",
    y = "Gamma correction"
  )
ggsave("TE_ELE.pdf", width=4.5, height = 3)
