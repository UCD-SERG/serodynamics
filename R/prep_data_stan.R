#' Prepare data for Stan
#'
#' @param dataframe a [data.frame] containing case data
#' @param biomarker_column [character] string indicating
#' which column contains antigen-isotype names
#' @param verbose whether to produce verbose messaging
#' @param add_newperson whether to add an extra record with missing data
#'
#' @returns a `prepped_stan_data` object (a [list] with Stan-formatted data)
#' @export
#'
#' @examples
#' set.seed(1)
#' raw_data <-
#'   serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(n = 5)
#' prepped_data <- prep_data_stan(raw_data)
prep_data_stan <- function(
    dataframe,
    biomarker_column = get_biomarker_names_var(dataframe),
    verbose = FALSE,
    add_newperson = TRUE) {
  
  # First use existing prep_data function to get the base structure
  jags_data <- prep_data(
    dataframe = dataframe,
    biomarker_column = biomarker_column,
    verbose = verbose,
    add_newperson = add_newperson
  )
  
  # Convert to Stan format
  # Stan requires explicit max dimensions
  max_nsmpl <- max(jags_data$nsmpl)
  
  # Create padded arrays (Stan doesn't handle ragged arrays like JAGS)
  # We need to pad smpl.t and logy to max_nsmpl
  nsubj <- jags_data$nsubj
  n_antigen_isos <- jags_data$n_antigen_isos
  
  # Initialize with zeros (will be ignored in model for obs > nsmpl[subj])
  smpl_t_padded <- array(0, dim = c(nsubj, max_nsmpl))
  logy_padded <- array(0, dim = c(nsubj, max_nsmpl, n_antigen_isos))
  
  # Fill in actual data
  for (subj in 1:nsubj) {
    n_obs <- jags_data$nsmpl[subj]
    if (n_obs > 0) {
      smpl_t_padded[subj, 1:n_obs] <- jags_data$smpl.t[subj, 1:n_obs]
      for (k in 1:n_antigen_isos) {
        logy_padded[subj, 1:n_obs, k] <- jags_data$logy[subj, 1:n_obs, k]
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
  stan_data <- stan_data |>
    structure(
      class = c("prepped_stan_data", "list"),
      antigens = attributes(jags_data)$antigens,
      n_antigens = attributes(jags_data)$n_antigens,
      ids = attributes(jags_data)$ids
    )
  
  return(stan_data)
}
