#' @title Prepare data for the Chapter 2 Stan models
#' @author Kwan Ho Lee
#' @description
#' Converts a `case_data` [data.frame] into the padded list `model_2a.stan` and
#' `model_2a_indep.stan` expect. It reuses the package's existing [prep_data()]
#' (the JAGS data builder, already in `main`) for the ragged structure, then pads
#' the time and measurement arrays to a rectangular shape for Stan.
#'
#' This reproduces the behavior of the Chapter 1 `prep_data_stan()` so the
#' Chapter 2 branch does not depend on the (unmerged) Chapter 1 Stan PR. The
#' returned list matches the `data` block of the Chapter 2 Stan models:
#' `nsubj`, `n_antigen_isos`, `n_params` (= 5), `nsmpl`, `max_nsmpl`, `smpl_t`
#' `[nsubj, max_nsmpl]` (0-padded), and `logy` `[nsubj, max_nsmpl,
#' n_antigen_isos]` (0-padded). Padded positions are ignored by the models,
#' which loop only up to `nsmpl[subj]`.
#'
#' @param dataframe a `case_data` [data.frame].
#' @param biomarker_column [character] column holding antigen-isotype names.
#'   Defaults to the package's biomarker-name accessor.
#' @param verbose passed to [prep_data()].
#'
#' @returns a named [list] ready for CmdStanR, with attributes `antigens`,
#'   `n_antigens`, and `ids` attached (used for labeling predictions).
#' @export
prep_data_serodynamics_stan_2a <- function(
    dataframe,
    biomarker_column = get_biomarker_names_var(dataframe),
    verbose = FALSE) {

  # Ragged structure from the existing (main) JAGS data builder.
  jags_data <- prep_data(
    dataframe = dataframe,
    biomarker_column = biomarker_column,
    verbose = verbose,
    add_newperson = FALSE          # Stan handles "new person" in post-processing
  )

  # Stan cannot take NA; check the source data up front for a clear error.
  value_var <- serocalculator::get_values_var(dataframe)
  time_var  <- get_timeindays_var(dataframe)
  if (any(is.na(dataframe[[value_var]])) || any(is.na(dataframe[[time_var]]))) {
    stop("Stan data cannot contain NA values. Remove or impute missing ",
         "antibody measurements or time points before fitting.")
  }
  if (length(jags_data$nsmpl) == 0 || all(jags_data$nsmpl == 0)) {
    stop("No observations found in input data.")
  }

  nsubj          <- jags_data$nsubj
  n_antigen_isos <- jags_data$n_antigen_isos
  max_nsmpl      <- max(jags_data$nsmpl)

  smpl_t_padded <- array(0, dim = c(nsubj, max_nsmpl))
  logy_padded   <- array(0, dim = c(nsubj, max_nsmpl, n_antigen_isos))

  for (subj in seq_len(nsubj)) {
    n_obs <- jags_data$nsmpl[subj]
    if (n_obs > 0) {
      subj_times <- jags_data$smpl.t[subj, seq_len(n_obs)]
      if (any(is.na(subj_times))) {
        stop("NA observation time for subject ", subj, ".")
      }
      smpl_t_padded[subj, seq_len(n_obs)] <- subj_times
      for (k in seq_len(n_antigen_isos)) {
        subj_logy <- jags_data$logy[subj, seq_len(n_obs), k]
        if (any(is.na(subj_logy))) {
          stop("NA log(antibody) for subject ", subj, ", antigen ", k, ".")
        }
        logy_padded[subj, seq_len(n_obs), k] <- subj_logy
      }
    }
  }

  stan_data <- list(
    nsubj          = nsubj,
    n_antigen_isos = n_antigen_isos,
    n_params       = 5L,
    nsmpl          = as.integer(jags_data$nsmpl),
    max_nsmpl      = as.integer(max_nsmpl),
    smpl_t         = smpl_t_padded,
    logy           = logy_padded
  )

  structure(
    stan_data,
    class      = c("prepped_stan_data_2a", "list"),
    antigens   = attributes(jags_data)$antigens,
    n_antigens = attributes(jags_data)$n_antigens,
    ids        = attributes(jags_data)$ids
  )
}
