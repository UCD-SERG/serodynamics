#' Postprocess Stan model output
#'
#' @description
#' Converts a `stanfit` object returned by [rstan::sampling()] into an
#' `sr_model` tibble with the same column layout as [run_mod()].
#'
#' Extracted parameters are the natural-scale quantities computed in the
#' Stan `generated quantities` block:
#' `y0_nat`, `y1_nat`, `t1_nat`, `alpha_nat`, `shape_nat`.
#'
#' @param stan_fit A `stanfit` object from [rstan::sampling()].
#' @param ids Character vector of subject IDs (length `N`).
#' @param antigen_isos Character vector of antigen-isotype names (length `K`).
#' @param stratification Character scalar: stratification label used to
#'   populate the `Stratification` column.  Defaults to `"None"`.
#'
#' @returns A [tibble::tbl_df] with columns:
#'   `Iteration`, `Chain`, `Parameter`, `Iso_type`, `Stratification`,
#'   `Subject`, `value`.
#'
#' @seealso [run_mod_stan()]
#' @export
postprocess_stan_output <- function(
    stan_fit,
    ids,
    antigen_isos,
    stratification = "None") {

  # Extract natural-scale parameters from generated quantities
  param_names <- c("y0_nat", "y1_nat", "t1_nat", "alpha_nat", "shape_nat")
  param_labels <- c("y0", "y1", "t1", "alpha", "shape")

  N <- length(ids)
  K <- length(antigen_isos)

  # rstan::extract with permuted = FALSE returns [iter, chains, parameters]
  all_samples <- rstan::extract(stan_fit, pars = param_names, permuted = FALSE)

  n_iter   <- dim(all_samples)[1]
  n_chains <- dim(all_samples)[2]

  # Build long-format tibble for all subjects, biomarkers, and parameters
  rows <- vector("list", N * K * length(param_labels))
  idx  <- 1L

  for (k in seq_len(K)) {
    for (subj in seq_len(N)) {
      for (p in seq_along(param_labels)) {
        # Parameter name in Stan: e.g. "y0_nat[subj,k]"
        stan_par_name <- paste0(param_names[p], "[", subj, ",", k, "]")
        col_pos <- which(dimnames(all_samples)[[3]] == stan_par_name)

        if (length(col_pos) == 0L) {
          cli::cli_abort(
            "Stan parameter {.val {stan_par_name}} not found in stanfit object."
          )
        }

        # Flatten across chains: Iteration index increases across chains
        for (chain in seq_len(n_chains)) {
          iter_vals <- all_samples[, chain, col_pos]
          rows[[idx]] <- tibble::tibble(
            Iteration      = seq_len(n_iter),
            Chain          = chain,
            Parameter      = param_labels[p],
            Iso_type       = antigen_isos[k],
            Stratification = stratification,
            Subject        = ids[subj],
            value          = as.numeric(iter_vals)
          )
          idx <- idx + 1L
        }
      }
    }
  }

  dplyr::bind_rows(rows)
}
