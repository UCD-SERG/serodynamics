#' @title Posterior predictive check
#' @author Sam Schildhauer
#' @description
#'  `posterior_pred()` 
#' @param data A [base::data.frame()] with the following columns.
#' @returns An `sr_model` class object: a subclass of [dplyr::tbl_df] that
#' contains MCMC samples from the joint posterior distribution of the model
#' parameters, conditional on the provided input `data`, 
#' including the following:
#' @inheritDotParams prep_priors
#' @export
#' @example inst/examples/run_mod-examples.R
posterior_pred <- function(data, raw_dat
                    file_mod = serodynamics_example("model.jags"),
                    ...) {

  # First calculate mu_logy or the expected outcome based on given parameters
  dat_fit <- data |>
    tidyr::spread(Parameter, value)
  
  mu_logy <- calc_fit_mod(data, raw_dat)
  
  # Putting data together. Inside the JAGS model, must explicitly generate 
  # a replicated dataset y_rep using the SAME likelihood as the real data.
  
  y_rep[i,j] ~ dnorm(mu_hat[i,j], prec.logy[j])
  
  
    mutate(mu_logy = 
             beta <- bt(y0, y1, t1)
           yt <- ifelse(
             t <= t1,
             y0 * exp(beta * t),
             (y1^(1 - shape) - (1 - shape) * alpha * (t - t1))^(1 / (1 - shape))
           )))
 
}
