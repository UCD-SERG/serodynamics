#' @title Default print method for run_mod output
#' @author Sam Schildhauer
#' @description
#'  Will print a default output for a run_mod object that specifies the median
#'  value of the posterior distribution for serokinetic curve parameters (y0,
#'  y1, t1, alpha, shape) by stratification (if specified) and antigen/iso type.
#' @param obj A [serodynamics::sero_mod_output] object.
#' @returns A [dplyr::tbl_df] that contains the median value of the posterior
#' distribution of stratifications (if any specified), antigen/iso type, and
#' parameter value.
#' @export
#' @example inst/examples/run_mod-examples.R

print.sero_mod_output <- function(obj) {

  # Summarizing results
  df_obj <- data.frame("Parameter" = obj$Parameter, "Iso_type" = obj$Iso_type,
                       "Stratification" = obj$Stratification, 
                       "Value" = obj$value)
  if (unique(df_obj$Stratification == "None")) {
  to_print <- df_obj |>
    dplyr::group_by(Iso_type, Parameter) |>
    dplyr::summarize(median = median(Value)) |>
    tidyr::spread(Parameter, median)
  } else {
    to_print <- df_obj |>
      dplyr::group_by(Stratification, Iso_type, Parameter) |>
      dplyr::summarize(median = median(Value)) |>
      tidyr::spread(Parameter, median)
  }
  to_print
}
