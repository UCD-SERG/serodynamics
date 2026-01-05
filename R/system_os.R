# copied from `testthat`
system_os <- function() {
  tolower(Sys.info()[["sysname"]])
}
