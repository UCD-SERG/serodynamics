#' @title Parameter recode
#' @author Sam Schildhauer
#' @description
#'  `param_recode` recodes character numbers as their corresponding parameter.
#' @param x A [vector] of character numbers that represent parameters.
#' @returns A [vector] with recoded values.
#' @keywords internal
param_recode <- function(x) {
  map <- c("1" = "log(y0)", 
           "2" = "log(y1 - y0)",
           "3" = "log(t1)", 
           "4" = "log(alpha)", 
           "5" = "log(shape - 1)")
  unname(map[as.character(x)])
}
