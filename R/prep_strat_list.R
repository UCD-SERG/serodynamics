#' @title Prepare and validate a stratification list
#' @author Sam Schildhauer
#' @description
#'  `prep_strat_list()` builds the vector of stratum labels that [run_mod()]
#'  iterates over.
#'  When `strat` is `NA`, a single pseudo-stratum (`"None"`) is returned so the
#'  model runs once on the full data set.
#'  Otherwise the unique values of `data[[strat]]` are returned, with factor
#'  columns coerced to their character labels so the loop iterates over labels
#'  rather than the underlying integer codes.
#'  Rows with a missing stratification value are dropped with a warning, since
#'  they cannot be assigned to a stratum.
#' @param data A [base::data.frame()] containing the stratification column.
#' @param strat A [character] string naming the stratification column, or `NA`
#'  to run the model without stratification.
#' @returns A vector of stratum labels to loop over.
#' @keywords internal
prep_strat_list <- function(data, strat) {
  if (is.na(strat)) {
    return("None")
  }

  # The stratification variable must be an existing column.
  if (!strat %in% names(data)) {
    cli::cli_abort(c(
      "Can't stratify by {.field {strat}}.",
      "x" = "Column {.field {strat}} was not found in {.arg data}."
    ))
  }

  strat_list <- if (is.factor(data[[strat]])) {
    as.character(unique(data[[strat]])) # factor -> character labels
  } else {
    unique(data[[strat]]) # preserve character/numeric type
  }

  # Warn about and drop rows whose stratification value is missing.
  if (anyNA(strat_list)) {
    cli::cli_warn(c(
      "!" = "The stratification variable {.field {strat}} contains \\
             {.val {NA}} value{?s}.",
      "i" = "Rows with a missing stratification value are dropped and \\
             not modeled."
    ))
    strat_list <- strat_list |>
      purrr::discard(is.na)
  }

  # Once missing values are removed there must be something left to model.
  if (length(strat_list) == 0) {
    cli::cli_abort(c(
      "Can't stratify by {.field {strat}}.",
      "x" = "Column {.field {strat}} contains no non-missing values."
    ))
  }

  strat_list
}
