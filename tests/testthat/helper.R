# copied from `testthat`
system_os <- function() {
  tolower(Sys.info()[["sysname"]])
}

# Get darwin snapshot variant for macOS
#
# Returns "darwin" for macOS, NULL for other platforms (Linux/Windows).
# This is used for testthat snapshot testing where macOS produces different
# JAGS MCMC output due to platform-specific floating-point arithmetic and
# math library implementations, while Linux and Windows produce identical
# results.
darwin_variant <- function() {
  if (system_os() == "darwin") "darwin" else NULL
}

# Get snapshot variant for R >= 4.6
#
# Returns "r46" for R >= 4.6, NULL for older versions.
# In R 4.6, tibble::as_tibble() and dplyr::mutate() reorder object attributes
# differently when the input already has custom attributes, causing the `class`
# attribute to appear at the end instead of in position 2.
r46_variant <- function() {
  if (getRversion() >= "4.6") "r46" else NULL
}
