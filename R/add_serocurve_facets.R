#' @title Establishes Facets when Building Serocurve
#' @description 
#' Facets a `plot_serocurve()` plot by antigen-isotype and/or
#' Stratification, choosing a sensible default `ncol` when one isn't
#' supplied.
#' @param facet_by_antigen_iso [logical]; if [TRUE], facets the plot by
#'   antigen-isotype.  Defaults to [TRUE] when multiple antigen-isotypes are
#'   requested.
#' @param ncol [integer]; number of columns when faceting.  If [NULL]
#'   (default), a sensible value is chosen automatically.
#' @return A [ggplot2::ggplot] objec with facets
#' @keywords internal
add_serocurve_facets <- function(p, 
                                 curve_summary, 
                                 antigen_iso_col, 
                                 antigen_iso,
                                 facet_by_strat,
                                 facet_by_antigen_iso = length(antigen_iso) > 1,
                                 ncol = NULL) {
  facet_vars <- character(0)
  if (facet_by_antigen_iso) facet_vars <- c(facet_vars, antigen_iso_col)
  if (facet_by_strat)       facet_vars <- c(facet_vars, "Stratification")

  if (length(facet_vars) == 0) {
    return(p)
  }

  if (is.null(ncol)) {
    if (length(facet_vars) == 1L) {
      n_panels <- length(unique(curve_summary[[facet_vars[1L]]]))
    } else {
      n_panels <- length(unique(interaction(
        curve_summary[[facet_vars[1L]]],
        curve_summary[[facet_vars[2L]]]
      )))
    }
    ncol <- if (n_panels == 1L) {
      1L
    } else if (n_panels <= 4L) {
      2L
    } else {
      NULL
    }
  }

  facet_formula <- stats::as.formula(
    paste("~", paste(facet_vars, collapse = " + "))
  )
  p + ggplot2::facet_wrap(facet_formula, ncol = ncol)
}
