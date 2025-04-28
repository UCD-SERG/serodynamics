nepal_sees <- readr::read_csv(
                              here::here() |>
                                fs::path("/inst/extdata/
                                         SEES_Case_Nepal_ForSeroKinetics_
                                         02-13-2025.csv")) |>
  as_case_data(id_var = "person_id",
               biomarker_var = "antigen_iso",
               value_var = "result",
               time_in_days = "dayssincefeveronset")

usethis::use_data(nepal_sees, overwrite = TRUE)
