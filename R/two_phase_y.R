#' @title Two-phase Antibody Kinetics (deterministic curve)
#' @author Kwan Ho Lee
#' @description
#'  `two_phase_y()` returns the expected antibody level at time `t` for a
#'  simple two-phase model:
#'  an exponential rise from `y0` to `y1` up to time `t1`, followed by a
#'  power-law decay controlled by `alpha` and `rho`.
#'
#'  This is used for simulation and simple trajectory checks.
#'
#' @param t Numeric vector of times (days).
#' @param y0 Baseline level (> 0).
#' @param y1 Peak level (> y0).
#' @param t1 Time of peak (> 0, in days).
#' @param alpha Positive decay-rate parameter.
#' @param rho Shape parameter (> 1).
#'
#' @return A numeric vector of length `length(t)` with expected antibody levels.
#'
#' @details
#'  The function is fully vectorized in `t`. For numerical stability during
#'  decay, the inner term is clamped to be at least `1e-12`.
#'
#' @seealso [simulate_multi_b_long()], [simulate_multi_b_long2()], 
#' [make_ab_vec()]
#'
#' @export
#' @example inst/examples/examples-two_phase_y.R
two_phase_y <- function(t, y0, y1, t1, alpha, rho) {
  beta <- log(y1 / y0) / t1
  ifelse(
    t <= t1,
    y0 * exp(beta * t),
    {
      term <- 1 + (rho - 1) * alpha * y1^(rho - 1) * (t - t1)
      term <- pmax(term, 1e-12)
      y1 * term^(-1 / (rho - 1))
    }
  )
}
