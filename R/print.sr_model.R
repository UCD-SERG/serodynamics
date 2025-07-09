#' @title Default print for run_mod object of class sr_model
#' @author Sam Schildhauer
#' @description
#'  A default print method for class `sr_model` that includes the mean posterior
#'  distribution for antibody kinetic curve parameters by `Iso_type` and
#'  `Stratification` (if specified).
#' @param data A [serodynamics::sr_model] object output from the
#' [serodynamics::run_mod()] function.
#' @returns A [dplyr::grouped_df] that
#' contains the mean posterior distribution for antibody kinetic curve
#' parameters by `Iso_type` and `Stratification` (if specified).
#' @export
#' @example
#' print.sr_model(nepal_sees_output)
print.sr_model <- function(data) {
  data_group <- data |>
    dplyr::group_by(Stratification, Iso_type, Parameter) |>
    dplyr::summarise(mean_val = mean(value)) |>
    tidyr::spread(Parameter, mean_val)
  # Taking out stratification column if not specified
  if(unique(data$Stratification == "None")) {
    data_group <- data_group[,2:7]
  } 
  data_group
}
    
  
  
  