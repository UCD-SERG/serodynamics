#' @title Process JAGS Output to Extract Parameter Medians (Basic)
#' @author 
#'   Kwan Ho Lee
#' @description
#' This function extracts posterior parameter samples from a JAGS model run and computes 
#' the median values for each subject and antigen. It processes the data up to step 7,
#' including filtering, unpacking, extracting parameters, computing medians, renaming antigen codes,
#' and reshaping the data into a wide format.
#'
#' The antibody dynamic curve includes:
#' - y0 = baseline antibody concentration
#' - y1 = peak antibody concentration
#' - t1 = time to peak
#' - r = shape parameter
#' - alpha = decay rate
#'
#' @importFrom stringr str_extract
#'
#' @param jags_post A [list] output from `serodynamics::run_mod()`, containing posterior samples.
#' @param dataset A [data.frame] containing subject and antigen information.
#' @return A tibble with median parameter estimates for each subject and antigen in wide format.
#' @export
#' @example inst/examples/examples-process_jags_basic.R
process_jags_basic <- function(jags_post, dataset) {
  # Step 1: Filter dataset for rows where bldculres is "typhi"
  data_typhi <- dataset %>% 
    dplyr::filter(bldculres == "typhi")
  
  # Step 2: Unpack the JAGS posterior samples into a tidy data frame
  jags_unpack <- ggmcmc::ggs(jags_post$jags.post$typhi$mcmc)
  
  # Step 3: Extract parameter name, subject, and antigen_iso from the Parameter column
  jags_processed <- jags_unpack %>%
    dplyr::mutate(
      Parameter_clean = stringr::str_extract(Parameter, "^[a-zA-Z0-9]+"),
      Subject = as.numeric(stringr::str_extract(Parameter, "(?<=\\[)\\d+")),
      antigen_iso = as.numeric(stringr::str_extract(Parameter, "(?<=,)\\d+(?=\\])"))
    ) %>%
    dplyr::filter(!is.na(Parameter_clean))
  
  # Step 4: Remove the last subject (if it is an extra entry)
  jags_processed <- jags_processed %>%
    dplyr::filter(Subject <= max(Subject, na.rm = TRUE) - 1)
  
  # Step 5: Compute the median of the 'value' for each group defined by Subject, antigen_iso, and Parameter_clean
  param_medians <- jags_processed %>%
    dplyr::group_by(Subject, antigen_iso, Parameter_clean) %>%
    dplyr::summarize(median_value = median(value), .groups = "drop")
  
  # Step 6: Convert numeric antigen_iso codes to descriptive names
  param_medians <- param_medians %>%
    dplyr::mutate(antigen_iso = dplyr::case_when(
      antigen_iso == 1 ~ "HlyE_IgA",
      antigen_iso == 2 ~ "HlyE_IgG",
      TRUE ~ as.character(antigen_iso)
    ))
  
  # Step 7: Reshape the data into a wide format where each parameter becomes a column
  param_medians_wide <- param_medians %>%
    tidyr::pivot_wider(names_from = Parameter_clean, values_from = median_value)
  
  return(param_medians_wide)
}
