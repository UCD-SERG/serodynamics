#' Prepare data for Stan Model B
#'
#' @description
#' Converts the output of [prep_data()] into a named list suitable for
#' passing to `rstan::sampling()`. Missing values in the padded arrays are
#' replaced with `0`; Stan only accesses entries up to `n_obs[i]` per
#' subject, so the padding values are never used in the likelihood.
#'
#' The `mu_hyp` and `sigma_hyp` arguments correspond to the hyperprior
#' parameters from [prep_priors()]:
#' - `mu_hyp` maps to `mu_hyp_param` (prior means on the five log-scale
#'   curve parameters)
#' - `sigma_hyp` maps to `1 / sqrt(prec_hyp_param)` (prior standard
#'   deviations derived from the JAGS precision hyperparameter)
#'
#' @param prepped_jags_data A `prepped_jags_data` list returned by
#'   [prep_data()] (with `add_newperson = FALSE`).
#' @param mu_hyp A numeric vector of length 5 giving the prior means for
#'   the five log-scale curve parameters
#'   (`log_y0`, `log_delta`, `log_t1`, `log_alpha`, `log_shape_minus_1`).
#'   Defaults match the `mu_hyp_param` argument of [prep_priors()].
#' @param sigma_hyp A numeric vector of length 5 giving the prior standard
#'   deviations for the five log-scale curve parameters.
#'   Defaults are derived from the `prec_hyp_param` argument of
#'   [prep_priors()] as `1 / sqrt(prec_hyp_param)`.
#'
#' @returns A named [list] suitable for passing to `rstan::sampling()`.
#'   Contains the following elements:
#'   - `N` — number of subjects
#'   - `K` — number of antigen-isotype pairs
#'   - `max_obs` — maximum number of observations per subject
#'   - `n_obs` — integer vector of length `N` giving actual observations
#'   - `time_obs` — `N × max_obs` matrix of observation times
#'     (padded with `0`)
#'   - `log_y_obs` — `N × max_obs × K` array of log antibody levels
#'     (padded with `0`)
#'   - `mu_hyp` — vector of length 5 (hyperprior means)
#'   - `sigma_hyp` — vector of length 5 (hyperprior SDs)
#'
#' @seealso [prep_data()], [run_mod_stan()]
#' @export
#'
#' @examples
#' set.seed(1)
#' raw_data <-
#'   serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(n = 5)
#' prepped <- prep_data(raw_data, add_newperson = FALSE)
#' stan_data <- prep_data_stan(prepped)
#' str(stan_data)
prep_data_stan <- function(
    prepped_jags_data,
    mu_hyp = c(1.0, 7.0, 1.0, -4.0, -1.0),
    sigma_hyp = 1.0 / sqrt(c(1.0, 0.00001, 1.0, 0.001, 1.0))) {

  smpl_t <- prepped_jags_data$smpl.t
  logy   <- prepped_jags_data$logy
  nsmpl  <- prepped_jags_data$nsmpl

  # Replace NA padding values with 0; Stan only reads positions <= n_obs[i]
  smpl_t[is.na(smpl_t)] <- 0.0
  logy[is.na(logy)]     <- 0.0

  list(
    N        = unname(prepped_jags_data$nsubj),
    K        = unname(prepped_jags_data$n_antigen_isos),
    max_obs  = unname(ncol(smpl_t)),
    n_obs    = as.integer(nsmpl),
    time_obs = unname(smpl_t),
    log_y_obs = unname(logy),
    mu_hyp   = mu_hyp,
    sigma_hyp = sigma_hyp
  )
}
