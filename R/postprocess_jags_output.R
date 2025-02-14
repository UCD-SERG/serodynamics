#' Postprocess JAGS output
#'
#' @param jags_output output from [runjags::run.jags()]
#'
#' @returns a [tibble::tbl_df]
#' @export
#'
postprocess_jags_output <- function(jags_output) {
  mcmc_list <- coda::as.mcmc.list(jags_output)

  mcmc_df <- ggmcmc::ggs(mcmc_list)

  wide_predpar_df <- mcmc_df |>
    mutate(
      parameter = sub("^(\\w+)\\[.*", "\\1", .data$Parameter),
      index_id =
        sub("^\\w+\\[(\\d+),.*", "\\1", .data$Parameter) |>
        as.numeric(),
      antigen_iso =
        sub("^\\w+\\[\\d+,(\\d+).*", "\\1", .data$Parameter) |>
        as.numeric()
    ) |>
    mutate(
      index_id = .data$index_id |>
        factor(labels = c(unique(.data$index_id), "newperson")),
      antigen_iso = .data$antigen_iso |>
        factor(labels = unique(.data$antigen_iso))
    ) |>
    filter(.data$index_id == "newperson") |>
    select(-all_of("Parameter")) |>
    tidyr::pivot_wider(
      names_from = "parameter",
      values_from = "value"
    ) |>
    rowwise() |>
    droplevels() |>
    ungroup() |>
    rename("r" = "shape")

  # Assuming wide_predpar_df is your data frame
  curve_params <- wide_predpar_df

  # Set class and attributes for serocalculator
  class(curve_params) <- c("curve_params", class(curve_params))
  antigen_isos <- unique(curve_params$antigen_iso)
  attr(curve_params, "antigen_isos") <- antigen_isos

  to_return <- curve_params |>
    mutate(
      iter = .data$Iteration,
      chain = .data$Chain,
    ) |>
    select(
      all_of(
        c(
          "antigen_iso",
          "iter",
          "chain",
          "y0",
          "y1",
          "t1",
          "alpha",
          "r"
        )
      )
    )

  return(to_return)
}
