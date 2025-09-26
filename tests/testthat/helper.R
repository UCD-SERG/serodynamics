# copied from https://github.com/bcgov/ssdtools/blob/4c52d2b87ea09405cd06325877952e50faf5c708/R/helpers.R # nolint line_length_linter

save_csv <- function(x) {
  path <- tempfile(fileext = ".csv")
  readr::write_csv(x, path)
  path
}

expect_snapshot_data <- function(x, name, digits = 6) {
  fun <- function(x) signif(x, digits = digits)
  lapply_fun <- function(x) I(lapply(x, fun))
  x <- dplyr::mutate(x, dplyr::across(tidyselect::where(is.numeric), fun))
  x <- dplyr::mutate(x, dplyr::across(tidyselect::where(is.list), lapply_fun))
  path <- save_csv(x)
  testthat::expect_snapshot_file(
    path,
    paste0(name, ".csv"),
    compare = testthat::compare_file_text
  )
}
