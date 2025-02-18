#' @export
#' @importFrom ggplot2 autoplot
ggplot2::autoplot

#' Plot case data
#'
#' @param log_x whether to log-transform the x-axis
#' @param object a `case_data` object
#' @param log_y whetehr to log-transform the y-axis
#'
#' @inheritDotParams ggplot2::geom_point
#' @inheritDotParams ggplot2::geom_line
#'
#' @returns a [ggplot2::ggplot]
#' @export
#'
#' @example inst/examples/examples-autoplot.case_data.R
autoplot.case_data <- function(object,
                               log_y = TRUE,
                               log_x = FALSE,
                               ...) {
  ids_varname <- serocalculator::ids_varname(object)
  values_varname <- serocalculator::get_values_var(object)
  time_varname <- get_timeindays_var(object)
  biomarkers_varname <-
    serocalculator::get_biomarker_names_var(object)
  to_return <-
    object |>
    ggplot2::ggplot() +
    ggplot2::aes(
      x = .data[[time_varname]],
      y = .data[[values_varname]],
      group = .data[[ids_varname]],
      col = .data[[ids_varname]]
    ) +
    ggplot2::geom_point(...) +
    ggplot2::geom_line(...) +
    ggplot2::facet_wrap(ggplot2::vars(.data[[biomarkers_varname]])) +
    ggplot2::guides(color = "none", group = "none") +
    ggplot2::theme_bw() +
    ggplot2::xlab("Time since seroconversion (days)") +
    ggplot2::labs(y = "Antibody response value")

  if (log_y) {
    min_nonzero_val <-
      object |>
      get_values() |>
      purrr::keep(~ . > 0) |>
      min()

    max_val <-
      object |>
      get_values() |>
      max()

    breaks1 <- c(0, 10^seq(
      min_nonzero_val |> log10() |> floor(),
      max_val |> log10() |> ceiling()
    ))

    to_return <-
      to_return +
      ggplot2::scale_y_continuous(
        labels = scales::label_comma(),
        transform = scales::pseudo_log_trans(
          sigma = min_nonzero_val / 10,
          base = 10
        ),
        breaks = breaks1
      )
  }

  if (log_x) {
    to_return <-
      to_return +
      ggplot2::scale_x_log10(labels = scales::label_comma())
  }

  return(to_return)
}
