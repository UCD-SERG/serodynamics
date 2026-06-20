#' @title Lean Chapter 1 fit (for comparison with Model 2a)
#' @description
#' Fits the **Chapter 1** model (`model.jags`) through the same lean path as
#' [run_mod_2a()] and returns the raw `runjags` object, monitoring the nodes
#' needed to compare against Model 2a (`mu.par`, `prec.par`). This is the
#' **same model, data, priors, and posterior** as
#' [run_mod()] — `run_mod()` simply adds post-processing on top; here we
#' keep the MCMC in `mcmc.list` form so it can be compared directly with a
#' Model 2a fit.
#'
#' Unstratified only (matching the typhoid example workflow).
#'
#' @param data A `serocalculator` case-data [data.frame].
#' @param file_mod Path to the Chapter 1 JAGS model (defaults to the packaged
#'   `model.jags`).
#' @param nchain,nadapt,nburn,nmc,niter MCMC controls (as in [run_mod()]).
#' @param ... Prior arguments forwarded to [prep_priors()].
#'
#' @returns A `runjags` object (its `$mcmc` is a [coda::mcmc.list]).
#' @export
fit_chapter1_lean <- function(data,
                              file_mod = serodynamics_example("model.jags"),
                              nchain = 4,
                              nadapt = 1000,
                              nburn = 1000,
                              nmc = 1000,
                              niter = 4000,
                              ...) {
  longdata <- prep_data(data)
  priors <- prep_priors(max_antigens = longdata[["n_antigen_isos"]], ...)
  nthin <- max(1, round(niter / nmc))
  
  runjags::run.jags(
    model = file_mod,
    data = c(longdata, priors),
    inits = initsfunction,
    method = "parallel",
    adapt = nadapt,
    burnin = nburn,
    thin = nthin,
    sample = nmc,
    n.chains = nchain,
    monitor = c("mu.par", "prec.par"),
    summarise = FALSE
  )
}
