#' @title Calculates fitted values for run_mod output
#' @description
#'  `calc_fit_mod()` takes antibody kinetic parameters and creates a fitted
#'  value corresponding to the estimated assay value (ex. ELISA units etc.) at
#'  time since infection (TSI).
#' @param t A [vector] of time points used to plot the fitted values.
#' @param y0 A [vector] of parameter estimates for baseline antibody level.
#' @param y1 A [vector] of parameter estimates specifying the .
#' @param t1 A [vector] of parameter estimates specifying the time to infect.
#' @param alpha A [vector] of parameter estimates specifying the antibody decay
#' rate.
#' @returns A [vector] of fitted
#'  value corresponding to the estimated assay value (ex. ELISA units etc.) at
#'  time since infection (TSI).
#' @export
#' @example inst/examples/run_mod-examples.R

calc_fit_mod <- function(data) {
  # Matching time_since_infection from original data set.
  data |> gather
  
  beta <- log(y1 / y0) / t1
  if (t <= t1) {
    y0 * exp(beta * t)
  } else {
    (y1^(1 - shape) - (1 - shape) * alpha * (t - t1))^(1 / (1 - shape))
  }
}


longdata <- prep_data(nepal_sees)
priors <- prep_priors(max_antigens = longdata$n_antigen_isos)

