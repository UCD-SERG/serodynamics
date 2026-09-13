#' @title Rebuild a precision matrix from its long-format rows
#'
#' @description
#' `unpack_jags()` encodes the two indices of `prec.par`
#' by pasting the recoded parameter names together with `", "`,
#' so a diagonal entry appears as `"log(alpha), log(alpha)"`.
#' This function reverses that encoding
#' and returns the matrix for a single posterior draw.
#'
#' @param rows A [data.frame] of `prec.par` rows
#'   for a single posterior draw,
#'   with columns `Parameter` and `value`.
#' @param par_names A character vector giving the parameter order,
#'   taken from the `mu.par` rows of the same draw.
#' @param call The calling environment, for error reporting.
#'
#' @returns A square numeric matrix with dimnames `par_names`.
#'
#' @keywords internal
#' @noRd
rebuild_prec_matrix <- function(rows,
                                par_names,
                                call = rlang::caller_env()) {
  n_par <- length(par_names)
  
  if (nrow(rows) != n_par^2) {
    cli::cli_abort(
      "Expected {.val {n_par^2}} {.field prec.par} entries
       but found {.val {nrow(rows)}}.",
      call = call
    )
  }
  
  label_parts <- strsplit(rows$Parameter, ", ", fixed = TRUE)
  
  malformed <- lengths(label_parts) != 2L
  if (any(malformed)) {
    cli::cli_abort(
      c(
        "Could not split {.val {sum(malformed)}} {.field prec.par}
         label{?s} into two parameter names.",
        "i" = "First offending label:
               {.val {rows$Parameter[malformed][1]}}."
      ),
      call = call
    )
  }
  
  row_index <- match(
    vapply(label_parts, `[`, character(1L), 1L), par_names
  )
  col_index <- match(
    vapply(label_parts, `[`, character(1L), 2L), par_names
  )
  
  if (anyNA(row_index) || anyNA(col_index)) {
    cli::cli_abort(
      "Some {.field prec.par} labels name parameters
       absent from {.field mu.par}.",
      call = call
    )
  }
  
  precision <- matrix(
    NA_real_,
    nrow = n_par,
    ncol = n_par,
    dimnames = list(par_names, par_names)
  )
  precision[cbind(row_index, col_index)] <- rows$value
  
  return(precision)
}
