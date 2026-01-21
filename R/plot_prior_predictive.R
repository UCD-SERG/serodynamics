#' Plot prior predictive check trajectories
#'
#' @description
#' Visualizes antibody trajectories simulated from priors to assess whether
#' prior distributions generate realistic curves for the study context.
#'
#' @details
#' Creates plots showing:
#' - Simulated antibody trajectories over time
#' - Separate panels for each biomarker (faceted)
#' - Optional overlay of observed data for comparison
#' - Multiple trajectories (if multiple simulations provided)
#'
#' The plot uses log-scale antibody values by default (matching the model),
#' but can optionally show natural scale.
#'
#' @param sim_data A simulated `prepped_jags_data` object from
#' [simulate_prior_predictive()], or a [list] of such objects
#' @param original_data Optional original `prepped_jags_data` object from
#' [prep_data()] to overlay observed data
#' @param log_scale [logical] Whether to plot on log scale (default = TRUE)
#' @param max_traj [integer] Maximum number of trajectories to plot per subject
#' (default = 100). Useful when `sim_data` contains many simulations.
#' @param show_points [logical] Whether to show individual observation points
#' (default = TRUE)
#' @param alpha [numeric] Transparency for trajectory lines (default = 0.3)
#'
#' @returns A [ggplot2::ggplot()] object
#'
#' @export
#' @examples
#' # Prepare data and priors
#' set.seed(1)
#' raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(n = 5)
#' prepped_data <- prep_data(raw_data)
#' prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)
#'
#' # Simulate and plot
#' sim_data <- simulate_prior_predictive(
#'   prepped_data, prepped_priors, n_sims = 20
#' )
#' plot_prior_predictive(sim_data, original_data = prepped_data)
plot_prior_predictive <- function(sim_data,
                                  original_data = NULL,
                                  log_scale = TRUE,
                                  max_traj = 100,
                                  show_points = TRUE,
                                  alpha = 0.3) {
  # Convert to list if single simulation
  if (inherits(sim_data, "prepped_jags_data")) {
    sim_list <- list(sim_data)
  } else {
    sim_list <- sim_data
  }

  # Limit number of trajectories to plot
  if (length(sim_list) > max_traj) {
    sim_list <- sim_list[seq_len(max_traj)]
    cli::cli_inform(
      "Plotting {max_traj} of {length(sim_data)} simulations for clarity"
    )
  }

  # Extract antigens from first simulation
  antigens <- attr(sim_list[[1]], "antigens")
  subject_ids <- attr(sim_list[[1]], "ids")

  # Convert simulated data to long format for plotting
  sim_plot_data <- do.call(
    rbind,
    lapply(seq_along(sim_list), function(sim_idx) {
      sim <- sim_list[[sim_idx]]

      do.call(rbind, lapply(seq_len(sim$nsubj), function(subj) {
        do.call(rbind, lapply(seq_len(sim$nsmpl[subj]), function(obs) {
          do.call(rbind, lapply(seq_along(antigens), function(k) {
            data.frame(
              subject = subject_ids[subj],
              time = sim$smpl.t[subj, obs],
              logy = sim$logy[subj, obs, k],
              biomarker = antigens[k],
              sim_id = sim_idx,
              stringsAsFactors = FALSE
            )
          }))
        }))
      }))
    })
  )

  # Remove NA values
  sim_plot_data <- sim_plot_data[!is.na(sim_plot_data$time) &
    !is.na(sim_plot_data$logy), ]

  # Transform to natural scale if requested
  if (!log_scale) {
    sim_plot_data$value <- exp(sim_plot_data$logy)
  } else {
    sim_plot_data$value <- sim_plot_data$logy
  }

  # Create base plot
  p <- ggplot2::ggplot(
    sim_plot_data,
    ggplot2::aes(x = .data$time, y = .data$value)
  )

  # Add observed data if provided
  if (!is.null(original_data)) {
    if (inherits(original_data, "prepped_jags_data")) {
      obs_plot_data <- do.call(
        rbind,
        lapply(seq_len(original_data$nsubj), function(subj) {
          do.call(
            rbind,
            lapply(seq_len(original_data$nsmpl[subj]), function(obs) {
              do.call(rbind, lapply(seq_along(antigens), function(k) {
                data.frame(
                  subject = subject_ids[subj],
                  time = original_data$smpl.t[subj, obs],
                  logy = original_data$logy[subj, obs, k],
                  biomarker = antigens[k],
                  stringsAsFactors = FALSE
                )
              }))
            })
          )
        })
      )

      obs_plot_data <-
        obs_plot_data[
          !is.na(obs_plot_data$time) &
            !is.na(obs_plot_data$logy),
        ]

      if (!log_scale) {
        obs_plot_data$value <- exp(obs_plot_data$logy)
      } else {
        obs_plot_data$value <- obs_plot_data$logy
      }

      # Add observed points
      if (show_points) {
        p <- p +
          ggplot2::geom_point(
            data = obs_plot_data,
            ggplot2::aes(x = .data$time, y = .data$value),
            color = "black",
            size = 2,
            alpha = 0.6
          )
      }

      # Add observed trajectories
      p <- p +
        ggplot2::geom_line(
          data = obs_plot_data,
          ggplot2::aes(
            x = .data$time,
            y = .data$value,
            group = .data$subject
          ),
          color = "black",
          linewidth = 0.5,
          alpha = 0.4
        )
    }
  }

  # Add simulated trajectories
  p <- p +
    ggplot2::geom_line(
      ggplot2::aes(
        group = interaction(.data$subject, .data$sim_id)
      ),
      color = "steelblue",
      alpha = alpha
    )

  # Facet by biomarker
  p <- p +
    ggplot2::facet_wrap(~biomarker, scales = "free_y", ncol = 2)

  # Add labels and theme
  y_label <- if (log_scale) "Log(Antibody Level)" else "Antibody Level"

  p <- p +
    ggplot2::labs(
      title = "Prior Predictive Check",
      subtitle = if (!is.null(original_data)) {
        "Blue = simulated from priors, Black = observed data"
      } else {
        "Simulated antibody trajectories from priors"
      },
      x = "Time (days)",
      y = y_label
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      strip.background = ggplot2::element_rect(fill = "grey90"),
      strip.text = ggplot2::element_text(face = "bold")
    )

  return(p)
}
