#' @title Build the combined JAGS input list for Model 2a
#' @description
#' Assembles the single named list that `model_2a.jags` consumes, by combining
#' the prepared longitudinal data ([prep_data()], reused unchanged from
#' Chapter 1) with the Model 2a priors ([prep_priors_2a()]). The biomarker
#' labels from `prep_data()` are carried along as an attribute so downstream
#' summaries can label the two biomarkers.
#'
#' @param data A [data.frame] in `serocalculator` case-data format (columns
#'   `antigen_iso`, `visit_num`, a value column, and a time column).
#' @param prec_lambda Prior precision of the factor loadings, forwarded to
#'   [prep_priors_2a()]. Default `0.25`.
#' @param add_newperson [logical]; forwarded to [prep_data()]. Default `TRUE`
#'   to match Chapter 1 (adds a dummy subject for posterior prediction).
#' @param ... Additional Chapter 1 prior arguments forwarded to
#'   [prep_priors_2a()].
#'
#' @returns A named [list] of JAGS inputs, with attribute `"antigens"` (the
#'   biomarker labels) and `"ids"` (subject ids).
#' @export
jags_data_2a <- function(data, prec_lambda = 0.25,
                         add_newperson = TRUE, ...) {
  longdata <- prep_data(data, add_newperson = add_newperson)

  n_bio <- longdata[["n_antigen_isos"]]
  if (n_bio != 2) {
    cli::cli_warn(c(
      "Model 2a is written for IgG/IgA-style biomarker pairs.",
      "i" = "Found {n_bio} biomarkers; the shared factor will couple all of
             them (same-parameter, rank-1). For a clean pair, subset to two."
    ))
  }

  priors <- prep_priors_2a(max_antigens = n_bio,
                           prec_lambda = prec_lambda, ...)

  jags_input <- c(longdata, priors)
  attr(jags_input, "antigens") <- attr(longdata, "antigens")
  attr(jags_input, "ids") <- attr(longdata, "ids")
  jags_input
}
