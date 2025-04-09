#' @title Process JAGS Output to Extract Parameter Medians and Predictive Intervals
#' @author Kwan Ho Lee
#' @description
#' This function extracts posterior parameter samples from a JAGS model run and computes the 
#' median along with the 2.5th and 97.5th percentiles for each parameter, for each subject and antigen.
#' These values can be used to generate predicted antibody response curves and form a posterior predictive interval.
#' 
#' The parameters describing the antibody dynamic curve are:
#' \describe{
#'   \item{y0}{Baseline antibody concentration.}
#'   \item{y1}{Peak antibody concentration.}
#'   \item{t1}{Time to peak.}
#'   \item{alpha}{Decay rate.}
#'   \item{shape}{Shape parameter.}
#' }
#' 
#' For each parameter (e.g. \code{y0}), the output tibble includes three columns:
#' \code{y0} (the median), \code{y0_lower} (the 2.5th percentile), and \code{y0_upper} (the 97.5th percentile).
#' 
#' When \code{run_until = 7}, the function returns the wide-format tibble without further subject mapping.
#' When \code{run_until = 9}, it filters the output by the specified \code{id} and \code{antigen_iso}.
#'
#' @importFrom stringr str_extract
#' @importFrom rlang .env
#'
#' @param jags_post A list output from \code{serodynamics::run_mod()}, containing posterior samples.
#' @param dataset A data frame containing subject and antigen information.
#' @param run_until An integer specifying the processing step (default is 9). Set to 7 to return 
#'   the wide-format tibble without filtering; set to 9 to perform subject mapping and filtering.
#' @param id An optional subject ID for filtering (required if \code{run_until} is 9).
#' @param antigen_iso An optional antigen ID for filtering (required if \code{run_until} is 9).
#'
#' @return A tibble with parameter estimates for each subject and antigen. For each parameter,
#' the median is provided along with its 2.5th and 97.5th percentiles (named with suffixes \code{_lower} and \code{_upper}). 
#' If \code{run_until} is 9, the output is filtered by the specified \code{id} and \code{antigen_iso}.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Example using a subject-specific JAGS output:
#' jags_results <- prepare_and_run_jags(id = "sees_npl_128", antigen_iso = "HlyE_IgA")
#' param_medians <- process_jags_output2(
#'   jags_post = jags_results$nepal_sees_jags_post2,
#'   dataset = jags_results$dataset,
#'   run_until = 9,
#'   id = "sees_npl_128",
#'   antigen_iso = "HlyE_IgA"
#' )
#' print(param_medians)
#' }


process_jags_output2 <- function(jags_post, dataset, run_until = 9, id = NULL, antigen_iso = NULL) {
  
  # Step 1: Filter dataset based on target_strat (bldculres == "typhi")
  data_typhi <- dataset %>% 
    dplyr::filter(bldculres == "typhi")
  
  # Step 2: Unpack JAGS posterior samples using ggmcmc::ggs
  jags_unpack <- ggmcmc::ggs(jags_post$jags.post$typhi$mcmc)
  
  # Step 3: Extract subject ID and antigen_iso from Parameter column
  jags_processed <- jags_unpack %>%
    dplyr::mutate(
      Parameter_clean = stringr::str_extract(Parameter, "^[a-zA-Z0-9]+"),
      Subject = as.numeric(stringr::str_extract(Parameter, "(?<=\\[)\\d+")),         # Extract subject number inside brackets
      antigen_iso = as.numeric(stringr::str_extract(Parameter, "(?<=,)\\d+(?=\\])"))  # Extract antigen_iso between comma and ]
    ) %>%
    dplyr::filter(!is.na(Parameter_clean))  # Remove rows where extraction failed
  
  # Step 4: Remove last subject (if applicable)
  jags_processed <- jags_processed %>%
    dplyr::filter(Subject <= max(Subject, na.rm = TRUE) - 1)
  
  # Step 5: Compute median and quantiles for each parameter per subject and antigen type.
  # This will compute:
  #   - median_value: the median
  #   - lower_value: 2.5th percentile
  #   - upper_value: 97.5th percentile
  param_medians <- jags_processed %>%
    dplyr::group_by(Subject, antigen_iso, Parameter_clean) %>%
    dplyr::summarize(
      median_value = median(value),
      lower_value = quantile(value, probs = 0.025),
      upper_value = quantile(value, probs = 0.975),
      .groups = "drop"
    )
  
  # Step 6: Convert antigen_iso numeric values to character names
  param_medians <- param_medians %>%
    dplyr::mutate(antigen_iso = dplyr::case_when(
      antigen_iso == 1 ~ "HlyE_IgA",
      antigen_iso == 2 ~ "HlyE_IgG",
      TRUE ~ as.character(antigen_iso)
    ))
  
  # Step 7: Reshape into wide format with predictive interval columns.
  # For example, if Parameter_clean is "y0", the columns will be named:
  #   y0         (median), y0_lower (2.5th percentile), and y0_upper (97.5th percentile).
  param_medians_wide <- param_medians %>%
    tidyr::pivot_wider(
      names_from = Parameter_clean,
      values_from = c(median_value, lower_value, upper_value),
      names_glue = "{Parameter_clean}{ifelse(.value=='median_value', '', ifelse(.value=='lower_value', '_lower', '_upper'))}"
    )
  
  # If only running until step 7, add the 'id' column from the input argument and return.
  if (run_until == 7) {
    if (!is.null(id)) {
      param_medians_wide <- param_medians_wide %>%
        dplyr::mutate(id = id)
    }
    return(param_medians_wide)
  }
  
  # For full processing (steps 8-9), check if required inputs are provided.
  if (is.null(id) || is.null(antigen_iso)) {
    stop("For full processing (run_until = 9), please provide both 'id' and 'antigen_iso' arguments.")
  }
  
  # Step 8: Ensure Correct Subject Mapping
  unique_ids <- unique(data_typhi$id)  # Get unique subject IDs from filtered dataset
  subject_mapping <- data.frame(
    id = unique_ids,
    Subject = seq_along(unique_ids)  # Assign numbers to match JAGS Subject numbering
  )
  
  param_medians_wide <- param_medians_wide %>%
    dplyr::left_join(subject_mapping, by = "Subject")
  
  # Step 9: Filter by the specified `id` and `antigen_iso`
  param_medians_wide_pick <- param_medians_wide %>%
    dplyr::filter(id == .env$id, antigen_iso == .env$antigen_iso)
  
  return(param_medians_wide_pick)
}

