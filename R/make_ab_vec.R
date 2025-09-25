#' @title Vectorized wrapper for serodynamics trajectory
#' @author Kwan Ho Lee
#' @description
#'  `make_ab_vec()` creates a vectorized version of an antibody trajectory
#'  function. By default, it wraps the internal
#'  `serodynamics::ab()` function (fitting the two-phase model).
#'
#'  This wrapper allows calls with vector inputs for `t, y0, y1, t1, alpha, 
#'  shape`.
#'
#' @param ab_fun A function with signature
#'  `f(t, y0, y1, t1, alpha, shape)`.  
#'  Default: internal serodynamics implementation (`serodynamics::ab`).
#'
#' @return A vectorized function that evaluates the antibody trajectory across
#'  multiple time points or parameter values.
#'
#' @seealso [two_phase_y()], [simulate_multi_b_long2()]
#'
#' @export
#' @example inst/examples/examples-make_ab_vec.R
make_ab_vec <- function(
  ab_fun = getFromNamespace("ab", "serodynamics")
) {
  Vectorize(
    function(t, y0, y1, t1, alpha, shape) ab_fun(t, y0, y1, t1, alpha, shape),
    vectorize.args = c("t", "y0", "y1", "t1", "alpha", "shape")
  )
}
