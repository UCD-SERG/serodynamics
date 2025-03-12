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
#' @param jags_post A [list] output from `serodynamics::run_mod()`, containing posterior samples.
#' @param remove_last_subject Logical; whether to remove the last subject (default: TRUE).
#' @return A tibble with median parameter estimates for each subject.
#' @export
#' @example inst/examples/examples-process_jags_output.R

process_jags_output <- function(jags_post, remove_last_subject = TRUE) {
  
  library(dplyr)
  library(tidyr)
  library(ggmcmc)
  library(stringr)
  
  # Step 1: Unpack JAGS posterior samples
  jags_unpack <- ggmcmc::ggs(jags_post$jags.post$typhi$mcmc)
  
  # Step 2: Extract subject ID and antigen_iso from Parameter column
  jags_processed <- jags_unpack %>%
    mutate(
      Parameter_clean = str_extract(Parameter, "^[a-zA-Z0-9]+"),
      Subject = as.numeric(str_extract(Parameter, "(?<=\\[)\\d+")),
      antigen_iso = as.numeric(str_extract(Parameter, "(?<=,)\\d+(?=\\])"))
    ) %>%
    filter(!is.na(Parameter_clean))
  
  # Step 3: Optionally remove the last subject's observations
  if (remove_last_subject) {
    max_subject <- max(jags_processed$Subject, na.rm = TRUE)
    jags_processed <- jags_processed %>% filter(Subject != max_subject)
  }
  
  # Step 4: Compute median for each parameter per subject and antigen type
  param_medians <- jags_processed %>%
    group_by(Subject, antigen_iso, Parameter_clean) %>%
    summarize(median_value = median(value), .groups = "drop")
  
  # Step 5: Reshape into wide format
  param_medians_wide <- param_medians %>%
    pivot_wider(names_from = Parameter_clean, values_from = median_value)
  
  return(param_medians_wide)
}
