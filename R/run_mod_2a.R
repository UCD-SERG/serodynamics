#' @title Fit Model 2a (Chapter 1 + alpha) with JAGS
#' @author Kwan Ho Lee
#' @description
#' Fits the Model 2a extension of `model.jags`. Model 2a keeps Chapter 1's
#' within-biomarker covariance blocks intact (`Sigma_G`, `Sigma_A` via the
#' same Wishart prior) and adds same-parameter cross-biomarker covariances
#' through a shared latent factor per kinetic parameter:
#' \deqn{par_{i,k,p} = \mu_{k,p} + w_{i,k,p} + \lambda_{k,p}\, f_{i,p},}
#' so that for two biomarkers the cross-biomarker covariance is
#' \eqn{c_p = \lambda_{1,p}\lambda_{2,p}} and Chapter 1 is recovered exactly
#' when all `lambda = 0`.
#'
#' This wrapper is intentionally lean and decomposed: it builds the JAGS input
#' ([jags_data_2a()]), runs the sampler, and returns the raw MCMC plus a tidy
#' cross-biomarker summary ([summarize_cross_2a()]). It does **not** reproduce
#' the full `sr_model` post-processing of [run_mod()]; the goal is a small,
#' debuggable object focused on the Chapter 2 covariance question.
#'
#' @param data A `serocalculator` case-data [data.frame] with **two**
#'   biomarkers (e.g. `HlyE_IgG` / `HlyE_IgA`).
#' @param file_mod Path to the Model 2a JAGS file. Defaults to the packaged
#'   `model_2a.jags`.
#' @param nchain,nadapt,nburn,nmc,niter Standard MCMC controls, matching
#'   [run_mod()] (chains, adaptation, burn-in, samples kept, total iterations).
#' @param prec_lambda Prior precision of the factor loadings. Default `0.25`.
#' @param extra_monitors Optional [character] vector of additional nodes to
#'   monitor (e.g. `"y0"`). The covariance machinery always monitors `lambda`,
#'   `mu.par`, `prec.par`, and `prec.logy`.
#' @param ... Additional Chapter 1 prior arguments forwarded to
#'   [prep_priors_2a()].
#'
#' @returns A list of class `"model_2a_fit"` with elements:
#'   - `mcmc`: the [coda::mcmc.list] of posterior draws;
#'   - `cross`: a tidy [data.frame] of posterior cross-biomarker covariance
#'     `c_p` and correlation `rho_p` per kinetic parameter;
#'   - `antigens`: the two biomarker labels;
#'   - `prec_lambda`: the loading-prior precision used;
#'   - `runjags`: the raw `runjags` object (for diagnostics such as PSRF).
#' @example inst/examples/run_mod_2a-examples.R
#' @export
run_mod_2a <- function(data,
                       file_mod = serodynamics_example("model_2a.jags"),
                       nchain = 4,
                       nadapt = 1000,
                       nburn = 1000,
                       nmc = 1000,
                       niter = 4000,
                       prec_lambda = 0.25,
                       extra_monitors = NULL,
                       ...) {
  jags_input <- jags_data_2a(data, prec_lambda = prec_lambda, ...)
  antigens <- attr(jags_input, "antigens")
  
  inits_fun <- make_inits_2a(
    n_antigen_isos = jags_input[["n_antigen_isos"]],
    n_params = jags_input[["n_params"]],
    mu_hyp = jags_input[["mu.hyp"]]
  )
  
  monitors <- unique(c("lambda", "mu.par", "prec.par", "prec.logy",
                       extra_monitors))
  nthin <- max(1, round(niter / nmc))
  
  fit <- runjags::run.jags(
    model = file_mod,
    data = jags_input,
    inits = inits_fun,
    method = "parallel",
    adapt = nadapt,
    burnin = nburn,
    thin = nthin,
    sample = nmc,
    n.chains = nchain,
    monitor = monitors,
    summarise = FALSE
  )
  
  mcmc <- fit[["mcmc"]]
  cross <- summarize_cross_2a(mcmc, antigens = antigens)
  
  structure(
    list(
      mcmc = mcmc,
      cross = cross,
      antigens = antigens,
      prec_lambda = prec_lambda,
      runjags = fit
    ),
    class = c("model_2a_fit", "list")
  )
}
