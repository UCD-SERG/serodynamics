#' @title Parameter recode
#' @author Sam Schildhauer
#' @description
#'  `param_recode` recodes character numbers as their corresponding parameter.
#' @param x A [vector] of character numbers that represent parameters.
#' @returns A [vector] with recoded values.
#' @keywords internal
param_recode <- function(x) {
  result <- dplyr::case_match(
    x,
    "1" ~ "y0",
    "2" ~ "y1",
    "3" ~ "t1",
    "4" ~ "alpha",
    "5" ~ "shape",
    .default = NA_character_
  )
  
  # Check for invalid parameter indices
  invalid <- unique(x[is.na(result)])
  if (length(invalid) > 0 && !all(is.na(invalid))) {
    cli::cli_abort(
      "param_recode(): invalid parameter index{?es}: {invalid}."
    )
  }
  
  return(result)
}
