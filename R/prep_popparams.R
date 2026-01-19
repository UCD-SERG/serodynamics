#' @title Preparing population parameters
#' @author Sam Schildhauer
#' @description
#'  `prep_popparams` filters a [data.frame] to only include population 
#'  parameters and renames the `Subject` variable as `Population_Parameters`.
#' @param x A [data.frame] with a `Subject` variable.
#' @returns A filtered [data.frame] with the `Subject` variable renamed.
#' @keywords internal
prep_popparams <- function(x) { 
  x <- x |>
    dplyr::filter(.data$Subject %in% c("mu.par", "prec.par", "prec.logy")) |>
    dplyr::rename(Population_Parameter = .data$Subject)
  return(x)
} 
