#' Simulate number of longitudinal observations
#'
#' @param dist_n_obs distribution of number of longitudinal observations
#' @param n number of participants to simulate
#'
#' @returns an [integer] [vector]
#' @export
#'
#' @examples
#'  dist_n_obs = tibble::tibble(n_obs = 1:5, prob = 1/5)
#'  dist_n_obs |> sim_n_obs(n = 10)
#' @keywords internal
sim_n_obs <- function(dist_n_obs, n) {
  sample(
    x = dist_n_obs$n_obs,
    size = n,
    replace = TRUE,
    prob = dist_n_obs$prob
  )
}
