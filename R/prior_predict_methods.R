#' @export
print.serodynamics_prior_predict <- function(x, ...) {
  print(x$plot)
  invisible(x)
}


#' @export
summary.serodynamics_prior_predict <- function(object, ...) {
  attr(object, "prior_summary")
}