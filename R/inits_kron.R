#' @title Safe inits for the Kronecker model
#' @author Kwan Ho Lee
#' @description
#'  `inits_kron()` wraps a base initializer (if provided) and makes sure
#'  that legacy pieces (`prec.par`) and Kronecker precision terms
#'  (`TauB`, `TauP`) are not preset. This avoids conflicts when running
#'  the multi-biomarker Kronecker model.
#'
#' @param chain Integer chain index passed through to the base inits function.
#' @param base_inits A function with signature `function(chain)` that returns a
#'  named list of initial values. Defaults to a simple RNG seed initializer.
#'
#' @return A [base::list()] of inits suitable for \pkg{runjags}.
#'
#' @export
#' @example inst/examples/examples-inits_kron.R
inits_kron <- function(chain,
                       base_inits = NULL) {
  if (is.null(base_inits)) {
    base_inits <- function(ch) {
      list(
        .RNG.name = "base::Mersenne-Twister",
        .RNG.seed = 123 + as.integer(ch)
      )
    }
  }
  z <- base_inits(chain)
  z$TauB <- NULL
  z$TauP <- NULL
  z$prec.par <- NULL
  z
}
