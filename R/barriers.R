source("utils.R")

# load the latest consolidated file
csvs = list.files(path       = file.path("..","deliverables"),
                  pattern    = 'barriers.csv',
                  full.names = TRUE)
dta  = read.csv(max(csvs))

##############################################################################
# plot the barriers
# uses seaborn colorblind palette
# https://github.com/mwaskom/seaborn/blob/master/seaborn/palettes.py
##############################################################################

c1 = "#0173B2"
c2 = "#DE8F05"
mods  = sort(unique(dta$mod))
plots = vector("list", length(mods))
for (i in seq_along(plots)) {
  #i=2
  sdta = filter(dta, mod==mods[i])
  f    = splinefun(sdta$beta,sdta$Lambda,method="mono")
  L    = sdta$Lambda[length(sdta$Lambda)]
  Lflr = floor(L*10)/10
  plots[[i]] = sdta %>% 
    ggplot(aes(x=beta,y=Lambda)) +
    geom_function(color=c1,fun=f) +
    geom_errorbarh(aes(xmin=0,xmax=beta),height=0,color=c1,size=0.25)+#,linetype="dotted"
    geom_errorbar(aes(ymin=0,ymax=Lambda),width=0,color=c2,size=0.25)+
    scale_x_continuous(expand = c(0.001, 0.001),n.breaks = 2)+
    scale_y_continuous(limits = c(0,L), expand = c(0.001, 0.001), breaks = c(0,Lflr))+
    my_theme() +
    theme(axis.title   = element_blank(),
          plot.title   = element_text(hjust = 0.5,size=9),
          panel.border = element_blank(),
          panel.grid.minor = element_blank(),
          axis.line    = element_line(color = 'black', size = 0.2),
          plot.margin  = margin(0, 2.5, 0, 2.5)) +
    labs(title = mods[i])
}
plot_grid(plotlist=plots) + 
  draw_plot_label(label = "Inverse temperature", x = 0.425, y = 0.0, 
                  fontface="plain", hjust = 0.1, size = 11) +
  draw_plot_label(label = "Tempering barrier", angle = 90, x = -0.04, y = 0.33, 
                  fontface="plain", hjust = 0.1, size = 11) +
  theme(plot.margin = margin(0, 0, 15, 15)) # from top clockwise

ggsave("barriers.pdf", width=6, height = 3)
