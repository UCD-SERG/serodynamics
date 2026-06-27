#' @title Fit the Chapter 2 serodynamics model (Model 2a) with Stan
#' @author Kwan Ho Lee
#' @description
#' Fits the within-host antibody model with the Chapter 2 Model 2a
#' ("Chapter1+alpha") covariance: Chapter 1's two free 5x5 within-biomarker
#' blocks are kept unchanged and only the 5 same-parameter cross-biomarker
#' covariances are added (a diagonal cross-block), so the model strictly nests
#' Chapter 1 (35 vs 30 covariance parameters). The Stan model fitted is
#' `inst/extdata/model_2a.stan`.
#'
#' This runner is **self-contained on `main`**: it does not call any function
#' added by the (unmerged) Chapter 1 Stan PR. It uses
#' [prep_data_serodynamics_stan_2a()] and [prep_priors_serodynamics_stan_2a()].
#'
#' Default sampler settings copy the values validated for the Chapter 1 Stan
#' model on this likelihood. In particular `max_treedepth = 12` and the default
#' initialization are deliberate: raising tree depth or narrowing `init` let
#' chains escape into a degenerate corner of the decay ridge in Chapter 1. Model
#' 2a adds only 5 cross-coupling parameters, so it should behave similarly;
#' still, raise `nadapt`/`niter` above the small defaults for production runs.
#'
#' @param data a `case_data` [data.frame].
#' @param file_mod optional explicit path to a `.stan` file. Defaults to the
#'   bundled `model_2a.stan`. (Validation code can point this at an alternative
#'   model with the same data/prior interface -- e.g. a block-diagonal Chapter 1
#'   baseline -- without this function depending on that file.)
#' @param nchain number of chains.
#' @param nadapt warmup iterations (`iter_warmup`).
#' @param niter sampling iterations (`iter_sampling`).
#' @param adapt_delta target acceptance (default 0.95).
#' @param max_treedepth maximum tree depth (default 12 -- see description).
#' @param init optional CmdStanR `init`. Leave `NULL` (default) unless testing
#'   shows otherwise.
#' @param seed optional RNG seed.
#' @param ... additional arguments passed to
#'   [prep_priors_serodynamics_stan_2a()] (e.g. `mu_hyp_param`).
#'
#' @returns the CmdStanR fit object (call `$summary()`, `$draws()` on it). Key
#'   quantities: `mu_par` (population means), `cross_cor` (same-parameter
#'   cross-biomarker correlations), `Sigma_joint` (the assembled 10x10 covariance,
#'   for conditional prediction), and `log_lik` (for LOO/WAIC). The antigens are
#'   attached as attribute `"antigens"`.
#' @export
run_serodynamics_stan_2a <- function(
    data,
    file_mod = NULL,
    nchain = 4,
    nadapt = 1000,
    niter = 1000,
    adapt_delta = 0.95,
    max_treedepth = 12,
    init = NULL,
    seed = NULL,
    ...) {

  use_default_model <- is.null(file_mod)
  if (use_default_model) {
    file_mod <- .find_stan_file_2a("model_2a.stan")
  }
  if (!file.exists(file_mod)) {
    stop("Stan file not found: ", file_mod,
         ". If running from source, ensure inst/extdata/ is on the path ",
         "(e.g. via devtools::load_all()).")
  }

  longdata <- prep_data_serodynamics_stan_2a(data)

  # model_2a.stan (Chapter1+alpha) is pairwise: it couples two biomarkers via a
  # diagonal cross-block, so it requires exactly 2 biomarkers. A user-supplied
  # file_mod (e.g. a block-diagonal baseline that works for any K) is not checked.
  if (use_default_model && longdata$n_antigen_isos != 2) {
    stop("model_2a.stan (Chapter1+alpha) requires exactly 2 biomarkers; ",
         "found ", longdata$n_antigen_isos, ".")
  }

  priorspec <- prep_priors_serodynamics_stan_2a(
    max_antigens = longdata$n_antigen_isos, ...)

  # The data list already carries n_params; drop the duplicate from the priors.
  priorspec_clean <- priorspec[setdiff(names(priorspec), "n_params")]
  stan_data <- c(longdata, priorspec_clean)
  # strip R-side attributes so CmdStanR sees a plain list of model inputs
  stan_data <- stan_data[!names(stan_data) %in%
                           c("class", "antigens", "n_antigens", "ids")]

  mod <- cmdstanr::cmdstan_model(file_mod)

  sample_args <- list(
    data            = stan_data,
    chains          = nchain,
    parallel_chains = nchain,
    iter_warmup     = nadapt,
    iter_sampling   = niter,
    adapt_delta     = adapt_delta,
    max_treedepth   = max_treedepth
  )
  if (!is.null(init)) sample_args$init <- init
  if (!is.null(seed)) sample_args$seed <- seed

  fit <- do.call(mod$sample, sample_args)

  attr(fit, "antigens") <- attributes(longdata)$antigens
  fit
}

# Locate a Chapter 2 Stan file, with a source-tree fallback for devtools workflows.
.find_stan_file_2a <- function(stan_name) {
  p <- system.file("extdata", stan_name, package = "serodynamics")
  if (nzchar(p) && file.exists(p)) return(p)
  for (cand in c(file.path("inst", "extdata", stan_name),
                 file.path("..", "inst", "extdata", stan_name))) {
    if (file.exists(cand)) return(cand)
  }
  stan_name  # last resort: let cmdstanr error with the bare name
}
