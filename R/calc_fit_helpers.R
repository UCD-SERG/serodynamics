# Helper functions for calc_fit_mod()

# Calculate fitted values for one subject 
fit_subject <- function(subject, draws_wide, original_data, decay_type,
                        min_value) { 
  # Posterior draws for this subject 
  subject_draws <- draws_wide |> 
    dplyr::filter(.data$Subject == subject) 
  # Observations for this subject 
  subject_data <- original_data |> 
    dplyr::filter(.data$Subject == subject) 
  # Join observations to posterior draws 
  matched_dat <- subject_draws |> 
    dplyr::right_join(subject_data, 
                      by = c("Subject", "Iso_type", "Stratification"), 
                      relationship = "many-to-many")
  # Calculate and summarize fitted values 
  fit_dat <- summarise_subject_fit(matched_dat = matched_dat, 
                                   decay_type = decay_type,  
                                   min_value = min_value)
  return(fit_dat)
}
  
# Calculate fitted values and summarize residuals 
summarise_subject_fit <- function(matched_dat, decay_type, min_value) { 
  fit_dat <- matched_dat |> 
    dplyr::mutate(fitted = ab(.data$t, .data$y0, .data$y1,
                              .data$t1, .data$alpha, .data$shape, 
                              decay_type = decay_type), 
                  residual = .data$result - .data$fitted, 
                  log_residual = log10(pmax(.data$result, min_value)) - 
                    log10(pmax(.data$fitted, min_value))) |> 
    dplyr::summarise(.by = dplyr::all_of(c(".obs_row", "Subject", "Iso_type", 
                                           "Stratification", "t")), 
                     fitted = median_or_na(.data$fitted), 
                     residual_low = quantile_or_na(.data$residual, 0.025), 
                     residual_high = quantile_or_na(.data$residual, 0.975), 
                     residual_med = median_or_na(.data$residual), 
                     log_residual_low = quantile_or_na(.data$log_residual, 
                                                       0.025), 
                     log_residual_high = quantile_or_na(.data$log_residual, 
                                                        0.975), 
                     log_residual_med = median_or_na(.data$log_residual)) |> 
    dplyr::rename(residual = "residual_med", 
                  log_residual = "log_residual_med") |> 
    dplyr::select(dplyr::all_of(c("Subject", "Iso_type", "Stratification", 
                                  "t", "fitted", "residual", "residual_low", 
                                  "residual_high", "log_residual", 
                                  "log_residual_low", "log_residual_high")))
  return(fit_dat)
}
  
  
# 2.5%/97.5%-style quantile that returns `NA` instead of erroring when `x`
# has no non-missing values (e.g. an unmatched right-joined observation).
quantile_or_na <- function(x, probs) {
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(NA_real_)
  }
  return(stats::quantile(x, probs = probs, names = FALSE))
}
  
# Median function that returns `NA` instead of erroring when `x`
# has no non-missing values (e.g. an unmatched right-joined observation).
median_or_na <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(NA_real_)
  }
  return(stats::median(x))
}
