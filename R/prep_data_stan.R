#' Prepare data for Stan
#'
#' @param dataframe a [data.frame] containing case data
#' @param biomarker_column [character] string indicating
#' which column contains antigen-isotype names
#' @param verbose whether to produce verbose messaging
#'
#' @returns a `prepped_stan_data` object (a named [list]) with the following
#'   elements ready for passing to CmdStanR:
#'   - `nsubj`: integer, number of subjects
#'   - `n_antigen_isos`: integer, number of antigen-isotype combinations
#'   - `n_params`: integer, number of curve parameters (always 5: y0, y1, t1,
#'     alpha, shape)
#'   - `nsmpl`: integer vector of length `nsubj`, number of observations per
#'     subject
#'   - `max_nsmpl`: integer, maximum of `nsmpl` (determines array dimensions)
#'   - `smpl_t`: numeric matrix `[nsubj, max_nsmpl]` of observation times.
#'     Positions beyond `nsmpl[subj]` are padded with **0** (not `NA`).
#'   - `logy`: numeric array `[nsubj, max_nsmpl, n_antigen_isos]` of log
#'     antibody values. Positions beyond `nsmpl[subj]` are padded with **0**.
#'     Unlike the JAGS output from [prep_data()], which uses `NA` for padding,
#'     Stan requires numeric values; the model ignores padded entries by
#'     looping only up to `nsmpl[subj]`.
#' @export
#'
#' @examples
#' set.seed(1)
#' raw_data <-
#'   serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(n = 5)
#' prepped_data <- prep_data_stan(raw_data)
#'
#' @seealso [sample_predictive_stan()] for posterior predictive
#'   sampling with Stan models
prep_data_stan <- function(
    dataframe,
    biomarker_column = get_biomarker_names_var(dataframe),
    verbose = FALSE) {
  
  # First use existing prep_data function to get the base structure
  jags_data <- prep_data(
    dataframe = dataframe,
    biomarker_column = biomarker_column,
    verbose = verbose,
    add_newperson = FALSE  # Force FALSE for Stan
  )
  
  # Check for NA values in the original input data (Stan cannot handle NA)
  # Note: jags_data arrays are padded with NA, so check original dataframe
  value_var <- serocalculator::get_values_var(dataframe)
  timeindays_var <- get_timeindays_var(dataframe)
  
  if (any(is.na(dataframe[[value_var]])) ||
        any(is.na(dataframe[[timeindays_var]]))) {
    cli::cli_abort(
      c(
        "Stan data cannot contain NA values.",
        "i" = paste(
          "The input data contains missing antibody measurements",
          "or time points."
        ),
        "i" = "Stan requires complete data for all observations.",
        "i" = paste(
          "Consider removing subjects/visits with missing data",
          "or imputing values."
        )
      )
    )
  }
  
  # Convert to Stan format
  # Stan requires explicit max dimensions
  # Validate that we have at least one subject with observations
  if (length(jags_data$nsmpl) == 0 || all(jags_data$nsmpl == 0)) {
    cli::cli_abort(
      c(
        "No observations found in input data.",
        "i" = "Stan models require at least one subject with observations.",
        "i" = "Check that your input data is not empty."
      )
    )
  }
  
  max_nsmpl <- max(jags_data$nsmpl)
  
  # Create padded arrays (Stan doesn't handle ragged arrays like JAGS)
  # We need to pad smpl.t and logy to max_nsmpl
  nsubj <- jags_data$nsubj
  n_antigen_isos <- jags_data$n_antigen_isos
  
  # Initialize with zeros (will be ignored in model for obs > nsmpl[subj])
  smpl_t_padded <- array(0, dim = c(nsubj, max_nsmpl))
  logy_padded <- array(0, dim = c(nsubj, max_nsmpl, n_antigen_isos))
  
  # Fill in actual data and validate no NA values in the arrays
  for (subj in seq_len(nsubj)) {
    n_obs <- jags_data$nsmpl[subj]
    if (n_obs > 0) {
      # Validate smpl.t has no NA values for this subject's observations
      subj_times <- jags_data$smpl.t[subj, seq_len(n_obs)]
      if (any(is.na(subj_times))) {
        cli::cli_abort(
          c(
            "Stan data cannot contain NA values in time points.",
            "i" = "Subject {subj} has NA values in observation times.",
            "i" = "Stan requires complete data for all observations."
          )
        )
      }
      smpl_t_padded[subj, seq_len(n_obs)] <- subj_times

      # Validate and copy logy values for each antigen
      for (k in seq_len(n_antigen_isos)) {
        subj_logy <- jags_data$logy[subj, seq_len(n_obs), k]
        if (any(is.na(subj_logy))) {
          cli::cli_abort(
            c(
              "Stan data cannot contain NA values in antibody measurements.",
              "i" = paste(
                "Subject {subj}, antigen {k} has NA values in",
                "log(antibody)."
              ),
              "i" = paste(
                "This can occur when a subject/visit exists but a particular",
                "antigen-isotype measurement is missing."
              ),
              "i" = "Stan requires complete data for all observations."
            )
          )
        }
        logy_padded[subj, seq_len(n_obs), k] <- subj_logy
      }
    }
  }
  
  stan_data <- list(
    nsubj = nsubj,
    n_antigen_isos = n_antigen_isos,
    n_params = 5,  # y0, y1, t1, alpha, shape
    nsmpl = as.integer(jags_data$nsmpl),
    max_nsmpl = as.integer(max_nsmpl),
    smpl_t = smpl_t_padded,
    logy = logy_padded
  )
  
  # Add attributes from JAGS data
  # Store antigens in a consistent order for use in predictions
  antigens_attr <- attributes(jags_data)$antigens
  stan_data <- stan_data |>
    structure(
      class = c("prepped_stan_data", "list"),
      antigens = antigens_attr,
      n_antigens = attributes(jags_data)$n_antigens,
      ids = attributes(jags_data)$ids
    )
  
  return(stan_data)
}
