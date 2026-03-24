#' Run Stan Model (Multivariate Observation)
#'
#' @description
#' `run_mod_stan()` fits the antibody kinetics model using RStan with a
#' multivariate (correlated) observation model.
#'
#' **Model B** replaces the K independent univariate normal likelihoods used
#' by [run_mod()] with a single K-variate normal likelihood per time point,
#' introducing a residual covariance matrix **Sigma_eps** that captures
#' correlations across antigen-isotype pairs within each observation.
#'
#' The two-phase kinetics curve (rise then decay) is identical to the JAGS
#' model in [run_mod()]; only the likelihood and the prior on the residual
#' structure differ.
#'
#' @section Stan model file:
#' The Stan model is stored in
#' `system.file("stan/model_b.stan", package = "serodynamics")`.
#' It is compiled once per R session and cached by `rstan`.
#'
#' @section Required package:
#' `rstan` must be installed to use this function.
#' It is listed as a suggested (optional) dependency of `serodynamics`.
#' Install it with `install.packages("rstan")`.
#'
#' @param data A `case_data` object from [as_case_data()].
#' @param model Character scalar: currently only `"model_b"` is supported.
#' @param chains Integer: number of MCMC chains (default `4`).
#' @param iter Integer: total iterations per chain including warmup
#'   (default `2000`).
#' @param warmup Integer: number of warmup iterations per chain
#'   (default `1000`).
#' @param adapt_delta Numeric: target Metropolis acceptance rate for the
#'   NUTS sampler (default `0.95`).
#' @param max_treedepth Integer: maximum tree depth for the NUTS sampler
#'   (default `12`).
#' @param strat Character scalar: name of a stratification variable in
#'   `data`, or `NA` for an unstratified analysis (default `NA`).
#' @param seed Integer or `NULL`: random seed passed to
#'   `rstan::sampling()` for reproducibility.
#' @param ... Additional arguments passed to [prep_data_stan()].
#'
#' @returns An `sr_model` class object: a subclass of [dplyr::tbl_df] with
#'   the same column structure as the output of [run_mod()]:
#'   `Iteration`, `Chain`, `Parameter`, `Iso_type`, `Stratification`,
#'   `Subject`, `value`.
#'
#'   Additional [attributes]:
#'   - `class`: includes `"sr_model"`.
#'   - `chains`: number of chains used.
#'   - `iter`: total iterations per chain.
#'   - `warmup`: warmup iterations per chain.
#'   - `adapt_delta`: target acceptance rate.
#'   - `Omega_eps`: K × K residual correlation matrix (posterior mean).
#'   - `Sigma_eps`: K × K residual covariance matrix (posterior mean).
#'   - `fitted_residuals`: data frame of fitted and residual values.
#'   - `stan.fit`: the raw `stanfit` object.
#'
#' @seealso [run_mod()] for the JAGS backend, [prep_data_stan()],
#'   [postprocess_stan_output()]
#' @export
#'
#' @examples
#' \dontrun{
#'   # Requires rstan to be installed
#'   set.seed(1)
#'   sim_data <- serocalculator::typhoid_curves_nostrat_100 |>
#'     sim_case_data(n = 5)
#'
#'   fit <- run_mod_stan(
#'     data   = sim_data,
#'     model  = "model_b",
#'     chains = 1,
#'     iter   = 200,
#'     warmup = 100
#'   )
#'   print(fit)
#' }
run_mod_stan <- function(
    data,
    model          = c("model_b"),
    chains         = 4L,
    iter           = 2000L,
    warmup         = 1000L,
    adapt_delta    = 0.95,
    max_treedepth  = 12L,
    strat          = NA,
    seed           = NULL,
    ...) {

  if (!requireNamespace("rstan", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "Package {.pkg rstan} is required to use {.fn run_mod_stan}.",
        "i" = "Install it with {.code install.packages(\"rstan\")}."
      )
    )
  }

  model <- match.arg(model)

  stan_file <- system.file("stan", paste0(model, ".stan"),
                           package = "serodynamics")
  if (!nzchar(stan_file)) {
    cli::cli_abort(
      c("Stan model file for {.val {model}} not found in the",
        "package installation.")
    )
  }

  # Compile Stan model (cached after first call within a session)
  stan_mod <- rstan::stan_model(file = stan_file)

  ## Build stratification list
  if (is.na(strat)) {
    strat_list <- "None"
  } else {
    strat_list <- unique(data[[strat]])
  }

  ## Shell to accumulate results
  all_results <- list()
  final_stan_fit <- NULL

  for (i in strat_list) {
    ## Subset data for this stratum
    if (is.na(strat)) {
      dl_sub <- data
    } else {
      dl_sub <- data |>
        dplyr::filter(.data[[strat]] == i)
    }

    ## Prepare data: do NOT add newperson (Stan handles predictions differently)
    prepped <- prep_data(dl_sub, add_newperson = FALSE)
    stan_data <- prep_data_stan(prepped, ...)

    ids          <- attr(prepped, "ids")
    antigen_isos <- attr(prepped, "antigens")

    ## Run NUTS sampler
    stan_fit <- rstan::sampling(
      object       = stan_mod,
      data         = stan_data,
      chains       = as.integer(chains),
      iter         = as.integer(iter),
      warmup       = as.integer(warmup),
      control      = list(
        adapt_delta   = adapt_delta,
        max_treedepth = as.integer(max_treedepth)
      ),
      seed         = if (is.null(seed)) {
        sample.int(.Machine$integer.max, 1L)
      } else {
        seed
      },
      refresh      = 0L  # suppress per-iteration progress output
    )
    final_stan_fit <- stan_fit

    ## Convert to long-format tibble
    stratum_results <- postprocess_stan_output(
      stan_fit      = stan_fit,
      ids           = ids,
      antigen_isos  = antigen_isos,
      stratification = as.character(i)
    )

    all_results[[as.character(i)]] <- stratum_results
  }

  ## Combine strata
  out <- dplyr::bind_rows(all_results)
  out <- tibble::as_tibble(out)

  ## Compute fitted values and residuals using last stratum's data
  fit_res <- calc_fit_mod(modeled_dat = out, original_data = dl_sub)

  ## Extract posterior mean of residual correlation/covariance matrices
  omega_samples <- rstan::extract(final_stan_fit, pars = "Omega_eps")$Omega_eps
  sigma_samples <- rstan::extract(final_stan_fit, pars = "Sigma_eps")$Sigma_eps
  omega_mean    <- apply(omega_samples, c(2, 3), mean)
  sigma_mean    <- apply(sigma_samples, c(2, 3), mean)

  colnames(omega_mean) <- antigen_isos
  rownames(omega_mean) <- antigen_isos
  colnames(sigma_mean) <- antigen_isos
  rownames(sigma_mean) <- antigen_isos

  ## Attach attributes to mirror run_mod() output
  out <- out |>
    structure(
      class         = union("sr_model", class(out)),
      chains        = chains,
      iter          = iter,
      warmup        = warmup,
      adapt_delta   = adapt_delta,
      Omega_eps     = omega_mean,
      Sigma_eps     = sigma_mean,
      fitted_residuals = fit_res,
      stan.fit      = final_stan_fit
    )

  out
}
