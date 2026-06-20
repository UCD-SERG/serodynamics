#' @title Compare Chapter 1 and Model 2a on the same data
#' @description
#' Fits **both** the Chapter 1 model ([fit_chapter1_lean()], the same posterior
#' as [run_mod()]) and **Model 2a** ([run_mod_2a()]) to the same data, then
#' reports:
#'   1. **What stays the same** — the shared population means `mu.par` and the
#'      within-biomarker variances, side by side, with absolute differences.
#'      Because Model 2a strictly nests Chapter 1, these should agree within
#'      MCMC error; large differences would signal a problem.
#'   2. **What Model 2a adds** — the cross-biomarker covariance `c_p` /
#'      correlation `rho_p`, which Chapter 1 cannot represent (it is
#'      structurally zero there).
#'
#' Use this to answer "what changed when I added cross-biomarker covariance?".
#'
#' **On "what improved".** A point-estimate comparison shows *consistency plus
#' the new term*; it does not by itself establish that Model 2a is *better*.
#' A rigorous improvement claim needs a model-selection criterion (DIC/WAIC; set
#' `dic = TRUE` for a best-effort DIC from each `runjags` fit) and, ultimately,
#' the downstream predictive task (e.g. time-since-infection / seroincidence
#' accuracy — MAE, RMSE, CrI coverage), which is the Chapter 2
#' simulation study rather than a single function.
#'
#' @param data A two-biomarker `serocalculator` case-data [data.frame]
#'   (e.g. `nepal_sees`).
#' @param nchain,nadapt,nburn,nmc,niter MCMC controls applied to **both** fits.
#' @param prec_lambda Factor-loading prior precision (Model 2a only).
#' @param dic [logical]; attempt to extract DIC from each `runjags` fit
#'   (best-effort; may re-run the models and can be slow). Default `FALSE`.
#' @param ... Prior arguments forwarded to **both** [prep_priors()] and
#'   [prep_priors_2a()].
#'
#' @returns A list of class `"model_2a_comparison"` with:
#'   - `shared`: [data.frame] comparing `mean`/`var` per biomarker x parameter
#'     (`*_ch1`, `*_2a`, and `*_absdiff`);
#'   - `cross`: Model 2a's cross-biomarker covariance/correlation summary;
#'   - `max_mean_absdiff`, `max_var_absdiff`: worst-case shared-parameter
#'     discrepancies (small = consistent);
#'   - `added`: the parameters whose `c_p` credible interval excludes zero;
#'   - `dic_ch1`, `dic_2a`: raw DIC objects when `dic = TRUE` (else `NULL`);
#'   - `fits`: the two underlying fit objects.
#' @export
compare_mod_2a <- function(data,
                           nchain = 4,
                           nadapt = 1000,
                           nburn = 1000,
                           nmc = 1000,
                           niter = 4000,
                           prec_lambda = 0.25,
                           dic = FALSE,
                           ...) {
  m1 <- fit_chapter1_lean(data, nchain = nchain, nadapt = nadapt,
                          nburn = nburn, nmc = nmc, niter = niter, ...)
  m2 <- run_mod_2a(data, nchain = nchain, nadapt = nadapt, nburn = nburn,
                   nmc = nmc, niter = niter, prec_lambda = prec_lambda, ...)
  
  s1 <- summarize_curve_params_2a(m1[["mcmc"]], with_loadings = FALSE)
  s2 <- summarize_curve_params_2a(m2[["mcmc"]], with_loadings = TRUE)
  
  shared <- dplyr::left_join(
    s1, s2,
    by = c("biomarker", "param"),
    suffix = c("_ch1", "_2a")
  )
  shared[["mean_absdiff"]] <- abs(shared[["mean_med_ch1"]] -
                                    shared[["mean_med_2a"]])
  shared[["var_absdiff"]] <- abs(shared[["var_med_ch1"]] -
                                   shared[["var_med_2a"]])
  
  cross <- m2[["cross"]]
  added <- cross[["param"]][cross[["cov_lo"]] > 0 | cross[["cov_hi"]] < 0]
  
  dic_ch1 <- if (dic) try(runjags::extract(m1, "dic"), silent = TRUE) else NULL
  dic_2a <- if (dic) {
    try(runjags::extract(m2[["runjags"]], "dic"), silent = TRUE)
  } else {
    NULL
  }
  
  out <- list(
    shared = shared,
    cross = cross,
    max_mean_absdiff = max(shared[["mean_absdiff"]]),
    max_var_absdiff = max(shared[["var_absdiff"]]),
    added = added,
    dic_ch1 = dic_ch1,
    dic_2a = dic_2a,
    fits = list(chapter1 = m1, model_2a = m2)
  )
  structure(out, class = c("model_2a_comparison", "list"))
}
