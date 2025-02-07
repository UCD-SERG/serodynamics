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
#'   sim_case_data(n = 10, max_n_obs = 20, followup_interval = 14) |> 
#'   autoplot(alpha = .5)
autoplot.case_data <- function(object, ...) {
  object |> 
    ggplot2::ggplot() +
    ggplot2::aes(x = obs_time,
                 y = value,
                 group = id,
                 col = id) +
    ggplot2::geom_point(...) +
    ggplot2::geom_line(...) +
    ggplot2::facet_wrap(ggplot2::vars(biomarker)) +
    ggplot2::guides(color = "none", group = "none") +
    ggplot2::theme_bw() +
    ggplot2::scale_y_log10()
    
}
