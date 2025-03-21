#' @title Process JAGS Output to Extract Parameter Medians
#' @author Kwan Ho Lee
#' @description
#' This function extracts posterior parameter samples from a JAGS model run and computes 
#' median values for each subject and antigen.
#' 
#' The antibody dynamic curve includes:
#' - y0 = baseline antibody concentration
#' - y1 = peak antibody concentration
#' - t1 = time to peak
#' - r = shape parameter
#' - alpha = decay rate
#' 
#' @importFrom stringr str_extract   
#' @importFrom rlang .env            
#' 
#' @param jags_post A [list] output from `serodynamics::run_mod()`, containing posterior samples.
#' @param dataset A [dataframe] containing subject and antigen information.
#' @param run_until An integer specifying the step until which the function should run (default: 9).
#' @param id An optional parameter specifying the subject ID for filtering (required if run_until = 9).
#' @param antigen_iso An optional parameter specifying the antigen ID for filtering (required if run_until = 9).
#' @return A tibble with median parameter estimates for each subject and antigen.
#' @export
#' @example inst/examples/examples-process_jags_output.R

process_jags_output <- function(jags_post, dataset, run_until = 9, id = NULL, antigen_iso = NULL) {
  
  # Step 1: Filter dataset based on target_strat (bldculres == "typhi")
  data_typhi <- dataset %>% 
    dplyr::filter(.data$bldculres == "typhi")
  
  # Step 2: Unpack JAGS posterior samples using ggmcmc::ggs
  jags_unpack <- ggmcmc::ggs(jags_post$jags.post$typhi$mcmc)
  
  # Step 3: Extract subject ID and antigen_iso from Parameter column
  jags_processed <- jags_unpack %>%
    dplyr::mutate(
      Parameter_clean = stringr::str_extract(.data$Parameter, "^[a-zA-Z0-9]+"),
      Subject = as.numeric(stringr::str_extract(.data$Parameter, "(?<=\\[)\\d+")),
      antigen_iso = as.numeric(stringr::str_extract(.data$Parameter, "(?<=,)\\d+(?=\\])"))
    ) %>%
    dplyr::filter(!is.na(.data$Parameter_clean))
  
  # Step 4: Remove last subject (if applicable)
  jags_processed <- jags_processed %>%
    dplyr::filter(.data$Subject <= max(.data$Subject, na.rm = TRUE) - 1)
  
  # Step 5: Compute median for each parameter per subject and antigen type
  param_medians <- jags_processed %>%
    dplyr::group_by(.data$Subject, .data$antigen_iso, .data$Parameter_clean) %>%
    dplyr::summarize(median_value = median(.data$value), .groups = "drop")
  
  # Step 6: Convert antigen_iso numeric values to character names
  param_medians <- param_medians %>%
    dplyr::mutate(antigen_iso = dplyr::case_when(
      .data$antigen_iso == 1 ~ "HlyE_IgA",
      .data$antigen_iso == 2 ~ "HlyE_IgG",
      TRUE ~ as.character(.data$antigen_iso)
    ))
  
  # Step 7: Reshape into wide format
  param_medians_wide <- param_medians %>%
    tidyr::pivot_wider(names_from = .data$Parameter_clean, values_from = .data$median_value)
  
  # If only running until step 7, add the 'id' column from the input argument and return
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
  unique_ids <- unique(data_typhi$id)
  subject_mapping <- data.frame(
    id = unique_ids,
    Subject = seq_along(unique_ids)
  )
  
  param_medians_wide <- param_medians_wide %>%
    dplyr::left_join(subject_mapping, by = "Subject")
  
  # Step 9: Filter by the specified `id` and `antigen_iso`
  param_medians_wide_pick <- param_medians_wide %>%
    dplyr::filter(.data$id == .env$id, .data$antigen_iso == .env$antigen_iso)
  
  return(param_medians_wide_pick)
}
