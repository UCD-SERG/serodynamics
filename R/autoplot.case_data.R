#' @export
#' @importFrom ggplot2 autoplot
ggplot2::autoplot

#' Plot case data
#'
#' @param object a `case_data` object
#' @inheritDotParams ggplot2::geom_point
#' @inheritDotParams ggplot2::geom_line
#'
#' @returns a [ggplot2::ggplot]
#' @export
#'
#' @examples
#' set.seed(1)
#' serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(n = 5, max_n_obs = 20, followup_interval = 14) |>
#'   autoplot(alpha = .5)
autoplot.case_data <- function(object, ...) {
  to_return <-
    object |>
    ggplot2::ggplot() +
    ggplot2::aes(
      x = .data |> get_timeindays(),
      y = .data$value,
      group = .data |> get_subject_ids(),
      col = .data |> get_subject_ids()
    ) +
    ggplot2::geom_point(...) +
    ggplot2::geom_line(...) +
    ggplot2::facet_wrap(
      ggplot2::vars(
        .data |> get_biomarker_names()
      )
    ) +
    ggplot2::guides(color = "none", group = "none") +
    ggplot2::theme_bw() +
    ggplot2::scale_y_log10() +
    ggplot2::xlab("Time since seroconversion (days)")

  return(to_return)
}
