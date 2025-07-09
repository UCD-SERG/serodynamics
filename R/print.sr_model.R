#' @title Default print for [serodynamics::run_mod()] output object of class
#' `sr_model`
#' @description
#'  A default print method for class `sr_model` that includes the mean posterior
#'  distribution for antibody kinetic curve parameters by `Iso_type` and
#'  `Stratification` (if specified).
#' @param data An `sr_model` output object from the
#' [serodynamics::run_mod()] function.
#' @returns A [dplyr::grouped_df] that
#' contains the mean posterior distribution for antibody kinetic curve
#' parameters by `Iso_type` and `Stratification` (if specified).
#' @export
#' @examples
#' print(nepal_sees_jags_output)
print.sr_model <- function(data) {
  data_group <- data |>
    dplyr::group_by(Stratification, Iso_type, Parameter) |>
    dplyr::summarise(mean_val = mean(value)) |>
    tidyr::spread(Parameter, mean_val) |>
    dplyr::arrange(Iso_type)
  # Taking out stratification column if not specified
  if(unique(data$Stratification == "None")) {
    data_group <- data_group[,2:7]
  } 
  data_group
}
    
  
  
  