# copied from `testthat`
system_os <- function() {
  tolower(Sys.info()[["sysname"]])
}

#' Get snapshot variant for current OS
#'
#' Returns "darwin" for macOS, NULL for other platforms (Linux/Windows).
#' This is used for testthat snapshot testing where macOS produces different
#' JAGS MCMC output due to platform-specific floating-point arithmetic and
#' math library implementations.
#'
#' @return Character string "darwin" on macOS, NULL on other platforms
#' @keywords internal
#' @examples
#' \dontrun{
#' snapshot_variant()
#' }
snapshot_variant <- function() {
  if (system_os() == "darwin") "darwin" else NULL
}
