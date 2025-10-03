#' @title Adds attributes
#' @description
#'  `add_jags_attrs` adds specified attributes to a [data.frame].
#' @param df A [data.frame].
#' @param attrs [attributes] to attach to the [data.frame].
#' @param original_data A [data.frame] of the original input dataset.
#' @returns A [data.frame] with specified [attributes] attached.
#' @keywords internal
add_jags_attrs <- function(df, attrs) {
  attributes(df) <- c(attributes(df), attrs)
  df
}
