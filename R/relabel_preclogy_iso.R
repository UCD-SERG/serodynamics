#' @title Relabel `prec.logy` population parameters by isotype
#' @author Sam Schildhauer
#' @description
#'  `relabel_preclogy_iso()` replaces the `Param` label of `prec.logy`
#'  population-parameter rows with their antigen/isotype label (`Iso_type`).
#'  This lets callers group `population_params` by `Parameter` to obtain
#'  per-isotype precision estimates, rather than collapsing all isotypes into a
#'  single `"prec.logy"` group.
#'  Rows that are not `prec.logy` population parameters, and rows lacking an
#'  `Iso_type` (e.g., the scalar/unindexed case), are left unchanged.
#' @param jags_unpacked A [tibble::tbl_df] returned by [unpack_jags()] after
#'  the `Iso_type` join, containing `.is_population_parameter`, `Subject`,
#'  `Iso_type`, and `Param` columns.
#' @returns The input with `Param` relabeled to `Iso_type` for `prec.logy`
#'  population-parameter rows.
#' @keywords internal
relabel_preclogy_iso <- function(jags_unpacked) {
  jags_unpacked |>
    dplyr::mutate(
      Param = dplyr::if_else(
        .data$.is_population_parameter &
          .data$Subject == "prec.logy" &
          !is.na(.data$Iso_type),
        .data$Iso_type,
        .data$Param
      )
    )
}
