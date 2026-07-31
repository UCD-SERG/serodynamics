#' Simulate observation (visit) times for one participant
#'
#' Generates the day-offsets of a participant's visits, starting at day 0
#' (infection / baseline). Two schemes are available:
#'
#' * `spacing = "uniform"` (default, **original behaviour**): visits are equally
#'   spaced by `followup_interval` days, with small random jitter of
#'   +/- `followup_variance` days between visits.
#' * `spacing = "log"` (**new, optional**): visits follow a fixed log-spaced
#'   grid -- dense early, sparse late -- so the antibody **peak** (a few days
#'   after infection) and the slow **decay tail** (months later) are both
#'   captured. A participant with `n_obs` visits receives the first `n_obs`
#'   points of the grid `c(0, exp-spaced(t_min .. t_max, max_n_obs - 1))`.
#'
#' The `"uniform"` path is byte-for-byte the original implementation, so
#' existing calls (three positional arguments) are unaffected.
#'
#' @param followup_interval [integer] mean days between visits (used when
#'   `spacing = "uniform"`)
#' @param followup_variance [integer] jitter (+/- days) between visits (used
#'   when `spacing = "uniform"`)
#' @param n_obs [integer] number of visits for this participant
#' @param spacing [character] visit-time scheme: `"uniform"` (default) or
#'   `"log"`
#' @param max_n_obs [integer] length of the full visit grid (**required** when
#'   `spacing = "log"`; typically the same `max_n_obs` passed to
#'   [sim_case_data])
#' @param t_min [numeric] first non-zero visit day for the log grid
#'   (default 3; used when `spacing = "log"`)
#' @param t_max [numeric] last visit day for the log grid, reached by a
#'   participant with `max_n_obs` visits (default 400; used when
#'   `spacing = "log"`)
#'
#' @returns a numeric [vector] of visit days (length `n_obs`), starting at 0
#' @export
#'
#' @examples
#' set.seed(1)
#' # original uniform scheme (unchanged):
#' sim_obs_times(followup_interval = 7, followup_variance = 1, n_obs = 5)
#'
#' # new log-spaced scheme (dense early, sparse late):
#' sim_obs_times(n_obs = 15, spacing = "log", max_n_obs = 15,
#'               t_min = 3, t_max = 400)
sim_obs_times_kl <- function(followup_interval,
                          followup_variance,
                          n_obs,
                          spacing = c("uniform", "log"),
                          max_n_obs = NULL,
                          t_min = 3,
                          t_max = 400) {
  spacing <- match.arg(spacing)
  
  if (spacing == "uniform") {
    # ---- ORIGINAL behaviour (unchanged) ----
    n_followup_obs <- n_obs - 1
    followup_range <- followup_interval + (-followup_variance:followup_variance)
    wait_times <-
      sample(
        followup_range,
        size = n_followup_obs,
        replace = TRUE
      )
    followup_dates <- c(0, cumsum(wait_times))
    return(followup_dates)
  }
  
  # ---- NEW: log-spaced grid (dense early, sparse late) ----
  if (is.null(max_n_obs)) {
    cli::cli_abort(
      c(
        "{.arg spacing} = {.str log} requires {.arg max_n_obs}.",
        "i" = "Pass the full visit-grid length (usually the same
               {.arg max_n_obs} given to {.fn sim_case_data})."
      )
    )
  }
  grid <-
    if (max_n_obs <= 1) {
      0
    } else {
      c(0, round(exp(seq(log(t_min), log(t_max), length.out = max_n_obs - 1))))
    }
  grid[seq_len(n_obs)]
}
