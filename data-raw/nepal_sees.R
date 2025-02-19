nepal_sees <- readr::read_csv(
                              here::here() |>
                                fs::path("/inst/extdata/
                                         SEES_Case_Nepal_ForSeroKinetics_
                                         02-13-2025.csv"))

# Kristen Code for importing and cleaning.
# dcase <-
#   read_csv("/Users/kristenaiemjoy/Documents/GitHub/serodynamics/
#             inst/extdata/elisa_clean_2024-06-05.csv") %>%
#   filter(Arm == "Prospective Cases" & Country == "Nepal") %>%
#   mutate(antigen_iso = paste(elisa_antigen, "_", elisa_antbdy_iso, sep=""),
#          antigen_iso = factor(antigen_iso)) %>%
#   filter(antigen_iso == "HlyE_IgG" | antigen_iso == "HlyE_IgA") %>%
#   mutate(person_id = paste0("sees_npl_", as.numeric(as.factor(pid))),
#          sample_id = paste0("N000_", as.numeric(as.factor(sid)))) %>%
#   select(Country, person_id, sample_id, bldculres, antigen_iso, studyvisit,
#          dayssincefeveronset,  result)

usethis::use_data(nepal_sees, overwrite = TRUE)
