#' @title Reconcile MCMC subject indices with subject IDs
#' @author Sam Schildhauer
#' @description
#'  `reconcile_subject_ids()` joins unpacked MCMC output to the subject ID
#'  lookup table and resolves a single `Subject` identifier for every row.
#'  - Individual-level parameters match a row in `ids`, so they receive the
#'  original subject ID.
#'  - Population-level parameters (e.g., `mu.par`, `prec.par`, `prec.logy`)
#'  have no matching ID, so they retain the parameter name produced by
#'  [unpack_jags()] as their identifier.
#'  The temporary index columns are then dropped and the cleaned parameter
#'  names (`Param`) are promoted to `Parameter` for downstream use.
#' @param jags_unpacked A [tibble::tbl_df] returned by [unpack_jags()]
#'  (after the `Iso_type` join), containing `Subject`, `Subnum`, `Param`,
#'  and `Parameter` columns.
#' @param ids A [tibble::tbl_df] with a `Subject_mcmc` column (the subject ID)
#'  and a `Subject` column (the MCMC index as a character string).
#' @returns A [tibble::tbl_df] with a single resolved `Subject` column and a
#'  `Parameter` column holding the cleaned parameter name.
#' @keywords internal
reconcile_subject_ids <- function(jags_unpacked, ids) {
  dplyr::left_join(jags_unpacked, ids, by = "Subject") |>
    dplyr::mutate(
      Subject_mcmc = dplyr::if_else(
        is.na(.data$Subject_mcmc),
        .data$Subject,
        .data$Subject_mcmc
      )
    ) |>
    dplyr::select(-c("Subnum", "Subject", "Parameter")) |>
    dplyr::rename("Subject" = "Subject_mcmc", "Parameter" = "Param")
}
