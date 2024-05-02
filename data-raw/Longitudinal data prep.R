
library(tidyverse)
## Data for Peter 



dL <- 
  read.csv("/Users/kristenaiemjoy/Dropbox/DataAnalysis/EntericFever/SEES Diagnostic Manuscript/Analysis/Source Data/elisa_clean_2023-02-23.csv") %>%
  filter(surgical != 1 | is.na(surgical))  %>%
  filter(Arm == "Prospective Cases" | Arm == "Retrospective Cases") %>%
  mutate(Hospitalized = ifelse((recloc == "Inpatient Department" | admithosp_seap == "Yes"), "Yes", "No")) %>% 
  mutate(antigen_iso = paste(elisa_antigen, "_", elisa_antbdy_iso, sep="")) %>%
  mutate(TimeInDays = ifelse(is.na(dayssincefeveronset), timesince0, dayssincefeveronset)) %>%
  mutate(TimePeriod = factor(TimePeriod, levels = c("Baseline","First visit", "28 days", "3 months","6 months", "12 months", "18 months", "24 months", "Last visit"))) %>%
  group_by(index_id, TimePeriod) %>% mutate(nVisits=n()) %>%
  ungroup() %>%
  select(index_id, Country, seapage, bldculres, Hospitalized, antigen_iso, result, TimePeriod,  postreinf, samplenum,  TimeInDays) %>%
  rename(age = seapage) %>%
  rename(visit = samplenum)  %>% 
  mutate(TimeInDays = ifelse(TimeInDays<0, 0, TimeInDays)) %>%
  mutate(visit = ifelse(is.na(visit) & TimePeriod == "Baseline", 1, visit))
  ##filter out all time points after reinfection
  # mutate(postreinf = ifelse(is.na(postreinf), 0, postreinf)) %>%
  # filter(postreinf!=1) %>%
  # select(-postreinf)
  

dR <- dL %>%
  select(-TimeInDays, -TimePeriod) %>%
  arrange(visit) %>%
  pivot_wider(names_from = antigen_iso, values_from = c(result), id_cols = c("index_id", "age", "visit", "Country", "bldculres", "Hospitalized")) %>%
  ungroup() %>%
  pivot_wider(names_from = visit, values_from = c(HlyE_IgA, HlyE_IgG, LPS_IgA, LPS_IgG, MP_IgA, MP_IgG, Vi_IgG),  id_cols = c("index_id", "age", "Country", "bldculres", "Hospitalized", 
                                                                                                                              ), names_prefix = "visit")


dT <- dL %>% 
  select(index_id, visit, TimePeriod, TimeInDays) %>%
  distinct(., .keep_all = T) %>%
  pivot_wider(names_from = visit, values_from = c(TimeInDays), id_cols = c("index_id"), names_prefix = "TimeInDays_visit") %>%
  ungroup()


dW <- merge(dR, dT, by = c("index_id")) 








