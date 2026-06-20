#' @title Infer JAGS array dimensions from coda column names
#' @description
#' Given the column names of an MCMC draws matrix (e.g. `"lambda[1,2]"`,
#' `"prec.par[2,3,4]"`), returns, for each base node, the maximum index in each
#' position (i.e. the array dimensions). Pure string parsing; no fitting.
#'
#' @param col_names [character] vector of coda column names.
#'
#' @returns A named [list]; each element is an [integer] vector of dimensions
#'   for that node.
#' @keywords internal
#' @noRd
jags_node_dims <- function(col_names) {
  bracketed <- grep("\\[", col_names, value = TRUE)
  base <- sub("\\[.*$", "", bracketed)
  idx_str <- sub("^.*\\[", "", sub("\\]$", "", bracketed))
  out <- list()
  for (b in unique(base)) {
    rows <- base == b
    idx_mat <- do.call(
      rbind,
      lapply(strsplit(idx_str[rows], ","), as.integer)
    )
    out[[b]] <- apply(idx_mat, 2, max)
  }
  out
}

#' @title Extract one array node as a matrix from a single MCMC draw
#' @description
#' Pulls a `d1 x d2` matrix for one base node out of a single named draw vector.
#' For a 2-D node (e.g. `lambda`) `slice` is `NULL`. For a 3-D node (e.g.
#' `prec.par[slice, i, j]`) pass the fixed first index in `slice`.
#'
#' @param draw_vec A named [numeric] vector (one row of the draws matrix).
#' @param node [character] base node name (e.g. `"lambda"`, `"prec.par"`).
#' @param d1,d2 [integer] output matrix dimensions.
#' @param slice Optional [integer]: fixed first index for a 3-D node.
#'
#' @returns A `d1 x d2` [matrix].
#' @keywords internal
#' @noRd
get_node_matrix <- function(draw_vec, node, d1, d2, slice = NULL) {
  out <- matrix(NA_real_, d1, d2)
  for (i in seq_len(d1)) {
    for (j in seq_len(d2)) {
      nm <- if (is.null(slice)) {
        sprintf("%s[%d,%d]", node, i, j)
      } else {
        sprintf("%s[%d,%d,%d]", node, slice, i, j)
      }
      out[i, j] <- draw_vec[[nm]]
    }
  }
  out
}
