# copied from `testthat`
system_os <- function() {
  tolower(Sys.info()[["sysname"]])
}

#' Get darwin snapshot variant for macOS
#'
#' Returns "darwin" for macOS, NULL for other platforms (Linux/Windows).
#' This is used for testthat snapshot testing where macOS produces different
#' JAGS MCMC output due to platform-specific floating-point arithmetic and
#' math library implementations, while Linux and Windows produce identical
#' results.
#'
#' @return Character string "darwin" on macOS, NULL on other platforms
#' @keywords internal
#' @examples
#' \dontrun{
#' darwin_variant()
#' }
darwin_variant <- function() {
  if (system_os() == "darwin") "darwin" else NULL
}
