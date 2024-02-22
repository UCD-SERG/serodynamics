
library(tidyverse)
library(reshape2)


d_overall <- melt(predpar) %>%
  rename(antigen_iso = Var1,
         parameter = Var2,
         iter = Var3) %>%
  mutate(antigen_iso = factor(antigen_iso, labels = c("HlyE_IgA", "HlyE_IgG", "LPS_IgA", "LPS_IgG", "MP_IgA", "MP_IgG", "Vi_IgG")),
         parameter = factor(parameter, labels = c("y0", "y1", "t1", "alpha", "r"))) %>%
  filter(antigen_iso != "MP_IgA" & antigen_iso != "MP_IgG") %>%
  mutate(value = exp(value)) %>%
  mutate(value = ifelse(parameter == "r", value+1, value)) %>%
  pivot_wider(names_from = "parameter", values_from="value") %>%
  rowwise() %>%
  mutate(y1 = y0+y1) %>%
  droplevels() %>%
  ungroup()
  #pivot_longer(names_to = "parameter", cols = c("y0", "y1", "t1", "alpha", "r")) %>%
  # mutate(ageCat = "Overall",
  #        Country = "All")


saveRDS(d_overall, "output/mcmc.rds")

