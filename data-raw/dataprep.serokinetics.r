# creating a mini data set here for the new serodynamcis package
# 02-13-25
# nepal, prospective cases only, hlye igg and iga only
library(tidyverse)

dcase <-
  serodynamics_example("elisa_clean_2024-06-05.csv") |>
  filter(Arm == "Prospective Cases" & Country == "Nepal") |>
  mutate(
    antigen_iso = paste(elisa_antigen, "_", elisa_antbdy_iso, sep = ""),
    antigen_iso = factor(antigen_iso)
  ) |>
  filter(antigen_iso == "HlyE_IgG" | antigen_iso == "HlyE_IgA") |>
  mutate(
    person_id = paste0("sees_npl_", as.numeric(as.factor(pid))),
    sample_id = paste0("N000_", as.numeric(as.factor(sid)))
  ) |>
  select(Country, person_id, sample_id, bldculres, antigen_iso,
         studyvisit, dayssincefeveronset, result)




write_csv(dcase, "SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv")
