nepal_sees <- readr::read_csv(
                              here::here() |>
                                fs::path("/inst/extdata/
                                         SEES_Case_Nepal_ForSeroKinetics_
                                         02-13-2025.csv"))

usethis::use_data(nepal_sees, overwrite = TRUE)
