#' @title Preparing population parameters
#' @author Sam Schildhauer
#' @description
#'  `param_recode` recodes character numbers as their corresponding parameter.
#' @param x A [data.frame] with a `Subject` variable.
#' @returns A filtered [data.frame] with rename `Subject` variable.
#' @keywords internal
  prep_popparams <- function(x) { 
    x |>
    dplyr::filter(.data$Subject %in% c("mu.par", "prec.par", "prec.logy")) |>
    dplyr::rename(Population_Parameter = .data$Subject)
    return(x)
  }