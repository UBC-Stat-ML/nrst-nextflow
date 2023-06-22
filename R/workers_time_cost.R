source("utils.R")

# load data
dta_ts  = read.csv(file.path("..","deliverables","raw_times.tsv"), header = FALSE, col.names = "time")
dta_bwt = read.csv(file.path("..","deliverables","busy_workers_over_time.csv"))
dta_wtc = read.csv(file.path("..","deliverables","workers_time_cost.csv"))

my_no_upper_right_border_thm = function(){
  theme(
    panel.border = element_blank(),
    axis.line    = element_line(color = 'black', linewidth = 0.2),
    panel.grid.minor = element_blank()
  )
}

##############################################################################
# plot: histogram of truncated times
##############################################################################

p_trunc = 0.025
t_trunc = quantile(dta_ts$time, 1-p_trunc)
phist = dta_ts %>% 
  mutate(time_tr = pmin(time, t_trunc)) %>% 
  ggplot(aes(x=time_tr)) +
  geom_histogram(aes(y = after_stat(count / sum(count))), color="grey35") +
  annotate("text", x = t_trunc, y = 3*p_trunc, label = sprintf(">%.1f", t_trunc), size=3)+
  my_theme() + 
  my_no_upper_right_border_thm()+
  labs(
    x = "CPU time of a tour (hours)",
    y = "Proportion"
  )

##############################################################################
# plot: busy workers over time
##############################################################################

seaborn_cb6 = c("#0173B2", "#029E73", "#D55E00", "#CC78BC", "#ECE133", "#56B4E9")

dta_plot = dta_bwt %>% 
  filter(between(nw, 32, 512)) %>% 
  mutate(fnw = factor(nw))

dta_et = dta_plot %>% 
  group_by(fnw) %>% 
  summarise(et = max(rs)) %>% 
  ungroup
pbwt = dta_plot %>% 
  ggplot() +
  geom_line(aes(x = rs, y=ws, color=fnw, linetype=fnw))+#,linewidth=1) +
  geom_point(data=dta_et, aes(x=et, color=fnw), y = 0, size = 2, show.legend = FALSE)+
  scale_color_manual(name="", values=seaborn_cb6) + 
  scale_linetype_manual(name="", values=seq(nrow(dta_et),1,by=-1)) + 
  my_theme() +
  my_no_upper_right_border_thm() +
  theme(
    legend.position=c(.75,.75),
    legend.key = element_blank(),
    legend.background=element_blank(),
    legend.spacing.y = unit(-.2, 'cm')
  ) +
  labs(
    x = "Elapsed time (hours)",
    y = "Busy workers"
  ) +
  guides(color=guide_legend(ncol=2,byrow=TRUE))

##############################################################################
# plot: elapsed time versus cost measures
##############################################################################

nws = sort(unique(dta_wtc$nw))
idxs = seq(1, length(nws), by=2)
breaks = nws[idxs]

pdta = dta_wtc %>%
  pivot_longer(!c(nw, rep), names_to = "measure") %>% 
  group_by(nw,measure) %>% 
  summarise(mid = mean(value), std = sd(value)) %>% 
  ungroup() %>% 
  mutate(low = mid-std, hi = mid+std) %>% 
  select(-std)

pet = pdta %>% 
  filter(measure=="et") %>% 
  ggplot(aes(x = nw)) +
  geom_line(aes(y=low), linetype = "dotted") +
  geom_line(aes(y=mid)) +
  geom_line(aes(y=hi), linetype = "dotted") +
  scale_x_log10(breaks=breaks, labels=as.character(breaks)) +
  scale_y_log10()+
  my_theme() +
  my_no_upper_right_border_thm()+
  labs(
    x = "Available workers",
    y = "Running time (hr)"
  )
pc = pdta %>% 
  filter(measure == "chpc") %>% 
  pivot_longer(!c(nw,measure)) %>%
  mutate(value_trans = value / min(value)) %>% 
  select(-value) %>% 
  pivot_wider(names_from = name, values_from = value_trans) %>% 
  ggplot(aes(x = nw))+#, color = measure, linetype = measure)) +
  geom_line(aes(y=low), linetype = "dotted") +
  geom_line(aes(y=mid)) +
  geom_line(aes(y=hi), linetype = "dotted") +
  # scale_color_discrete(name="", labels=c("clam"="Fair", "chpc"="Standard")) +
  # scale_linetype_discrete(name="", labels=c("clam"="Fair", "chpc"="Standard")) +
  scale_x_log10(breaks=breaks, labels=as.character(breaks)) +
  scale_y_log10()+
  my_theme() +
  my_no_upper_right_border_thm()+
  theme(
    legend.position=c(.3,.75),
    legend.key = element_blank(),
    legend.background=element_blank()
  )+
  labs(
    x = "Available workers",
    y = "Cost"
  )
plt = plot_grid(phist, pbwt, pet, pc)
ggsave("workers_time_cost.pdf", plot=plt, width=6, height = 3.2, device = cairo_pdf) # device needed on Linux to print unicode correctly
