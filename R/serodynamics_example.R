#' @title Get path to an example file
#' @description
#' The [serodynamics] package comes bundled with a number of sample files
#' in its `inst/extdata` directory.
#' This `serodynamics_example()` function make those sample files
#' easy to access.
#' @details Adapted from [readr::readr_example()] following the guidance in
#' <https://r-pkgs.org/data.html#sec-data-example-path-helper>.
#' @param file Name of file. If `NULL`, the example files will be listed.
#' @returns a [character] string providing
#' the path to the file specified by `file`,
#' or a vector or available files if `file = NULL`.
#' @export
#' @examples
#' serodynamics_example()
#' serodynamics_example("example_pop_data.csv")
serodynamics_example <- function(file = NULL) {
  if (is.null(file)) {
    dir(fs::path_package("extdata", package = "serodynamics"))
  } else {
    fs::path_package("extdata", file, package = "serodynamics")
  }
}
