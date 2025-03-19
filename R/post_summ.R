
#' @title Table of Summary of Jags Post Estimates
#' @author Sam Schildhauer
#' @description
#'  post_summ() takes a [list] output from [serodynamics::run_mod()]
#'  to summary table for parameter, antigen/antibody, and stratification
#'  combination.
#'  Defaults will produce every combination of antigen/antibody, parameters,
#'  and stratifications, unless otherwise specified.
#'  Antigen/antibody combinations and stratifications will vary by analysis.
#'  The antibody dynamic curve includes the following parameters:
#'  - y0 = baseline antibody concentration
#'  - y1 = peak antibody concentration
#'  - t1 = time to peak
#'  - r = shape parameter
#'  - alpha = decay rate
#' @param data A [list] outputted from run_mod().
#' @param iso Specify [character] string to produce tables of only a
#' specific antigen/antibody combination, entered with quotes. Default outputs
#' all antigen/antibody combinations.
#' @param param Specify [character] string to produce tables of only a
#' specific parameter, entered with quotes. Options include:
#' - `alpha` = posterior estimate of decay rate
#' - `r` = posterior estimate of shape parameter
#' - `t1` = posterior estimate of time to peak
#' - `y0` = posterior estimate of baseline antibody concentration
#' - `y1` = posterior estimate of peak antibody concentration
#' @param strat Specify [character] string to produce tables of specific
#' stratification entered in quotes.
#' @return A [data.frame] summarizing estimate mean, standard deviation (SD), 
#' median, and quantiles (2.5%, 25.0%, 50.0%, 75.0%, 97.5%).
#' @export
#' @examples
#' post_summ(data = serodynamics::nepal_sees_jags_post)

post_summ <- function(data,
                      iso = unique(data$curve_params$Iso_type),
                      param = unique(data$curve_params$Parameter_sub),
                      strat = unique(data$curve_params$Stratification)) {
  summarize_jags <- data[["curve_params"]]

  summarize_jags <- summarize_jags |>
    filter(.data$Iso_type %in% iso) |>
    filter(.data$Parameter_sub %in% param) |>
    filter(.data$Stratification %in% strat)

  summarize_jags <- summarize_jags |>
    dplyr::group_by(.data$Iso_type, .data$Parameter_sub, 
                    .data$Stratification) |>
    dplyr::summarize(Mean = round(mean(.data$value), 3), 
                     SD = round(sd(.data$value), 3), 
                     Median = round(median(.data$value), 3), 
                     `2.5%` = round(quantile(.data$value, 0.025), 3), 
                     `25.0%` = round(quantile(.data$value, 0.25), 3), 
                     `50.0%` = round(quantile(.data$value, 0.50), 3), 
                     `75.0%` = round(quantile(.data$value, 0.75), 3), 
                     `97.5%` = round(quantile(.data$value, 0.975), 3))
  summarize_jags
}
