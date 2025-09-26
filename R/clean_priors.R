#' @title Drop legacy/unused prior fields
#' @author Kwan Ho Lee
#' @description
#'  `clean_priors()` removes elements from a priors list that are not
#'  used by the Kronecker model. This helps avoid passing unused or
#'  conflicting parameters (like `omega`, `wishdf`, or `prec.par`) into JAGS.
#'
#' @param x A [base::list()] of priors (e.g., from [prep_priors()]).
#'
#' @return A [base::list()] with the legacy fields removed.
#'
#' @export
#' @example inst/examples/examples-clean_priors.R
clean_priors <- function(x) {
  drop <- intersect(names(x), c("omega", "wishdf", "Omega", "WishDF", 
                                "prec.par"))
  if (length(drop)) x <- x[setdiff(names(x), drop)]
  x
}
