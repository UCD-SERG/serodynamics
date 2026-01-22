#' Summarize prior predictive simulations
#'
#' @description
#' Provides diagnostic summaries of prior predictive simulations to identify
#' potential issues with prior specifications before fitting the model.
#'
#' @importFrom stats median quantile
#'
#' @details
#' This function checks for:
#' - Non-finite values (NaN, Inf, -Inf)
#' - Negative antibody values (which would be invalid on natural scale)
#' - Summary statistics by biomarker (min, max, median, IQR)
#' - Optional comparison to observed data ranges
#'
#' @param sim_data A simulated `prepped_jags_data` object from
#' [simulate_prior_predictive()], or a [list] of such objects
#' @param original_data Optional original `prepped_jags_data` object from
#' [prep_data()] to compare simulated vs observed ranges
#'
#' @returns A [list] containing:
#' - `n_sims`: Number of simulations summarized
#' - `validity_check`: [data.frame] with counts of finite, non-finite,
#'   and negative values by biomarker
#' - `range_summary`: [data.frame] with min, max, median, and IQR of
#'   simulated values by biomarker
#' - `observed_range`: (if `original_data` provided) [data.frame] with
#'   observed data ranges for comparison
#' - `issues`: [character] [vector] describing any detected problems
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
#' # Simulate and summarize
#' sim_data <- simulate_prior_predictive(
#'   prepped_data, prepped_priors, n_sims = 10
#' )
#' summary <- summarize_prior_predictive(
#'   sim_data, original_data = prepped_data
#' )
#' print(summary)
summarize_prior_predictive <- function(sim_data, original_data = NULL) {
  # Handle list of simulations or single simulation
  if (is.list(sim_data) && !inherits(sim_data, "prepped_jags_data")) {
    # It's a list of simulations
    n_sims <- length(sim_data)
    antigens <- attr(sim_data[[1]], "antigens")
    n_antigens <- sim_data[[1]]$n_antigen_isos

    # Extract values by biomarker across all simulations
    logy_by_biomarker <- lapply(seq_len(n_antigens), function(k) {
      vals <- do.call(
        c,
        lapply(sim_data, function(x) as.vector(x$logy[, , k]))
      )
      vals[!is.na(vals)]
    })
  } else {
    # Single simulation
    n_sims <- 1
    antigens <- attr(sim_data, "antigens")
    n_antigens <- sim_data$n_antigen_isos

    logy_by_biomarker <- lapply(seq_len(n_antigens), function(k) {
      vals <- as.vector(sim_data$logy[, , k])
      vals[!is.na(vals)]
    })
  }

  # Validity check for each biomarker
  validity_check <- data.frame(
    biomarker = antigens,
    n_finite = vapply(
      logy_by_biomarker,
      function(x) sum(is.finite(x)),
      FUN.VALUE = integer(1)
    ),
    n_nonfinite = vapply(
      logy_by_biomarker,
      function(x) sum(!is.finite(x)),
      FUN.VALUE = integer(1)
    ),
    n_negative = vapply(
      logy_by_biomarker,
      function(x) sum(is.finite(x) & x < log(0.01)),
      FUN.VALUE = integer(1)
    ),
    stringsAsFactors = FALSE
  )

  # Range summary for each biomarker (on log scale)
  range_summary <- data.frame(
    biomarker = antigens,
    min = vapply(logy_by_biomarker, function(x) {
      if (length(x) > 0 && any(is.finite(x))) {
        min(x[is.finite(x)])
      } else {
        NA_real_
      }
    }, FUN.VALUE = numeric(1)),
    q25 = vapply(logy_by_biomarker, function(x) {
      if (length(x) > 0 && any(is.finite(x))) {
        quantile(x[is.finite(x)], 0.25)
      } else {
        NA_real_
      }
    }, FUN.VALUE = numeric(1)),
    median = vapply(logy_by_biomarker, function(x) {
      if (length(x) > 0 && any(is.finite(x))) {
        median(x[is.finite(x)])
      } else {
        NA_real_
      }
    }, FUN.VALUE = numeric(1)),
    q75 = vapply(logy_by_biomarker, function(x) {
      if (length(x) > 0 && any(is.finite(x))) {
        quantile(x[is.finite(x)], 0.75)
      } else {
        NA_real_
      }
    }, FUN.VALUE = numeric(1)),
    max = vapply(logy_by_biomarker, function(x) {
      if (length(x) > 0 && any(is.finite(x))) {
        max(x[is.finite(x)])
      } else {
        NA_real_
      }
    }, FUN.VALUE = numeric(1)),
    stringsAsFactors = FALSE
  )

  # Optional comparison with observed data
  observed_range <- NULL
  if (!is.null(original_data)) {
    if (!inherits(original_data, "prepped_jags_data")) {
      cli::cli_warn(
        c(
          "{.arg original_data} is not a {.cls prepped_jags_data}",
          "object; skipping comparison"
        )
      )
    } else {
      obs_logy_by_biomarker <- lapply(seq_len(n_antigens), function(k) {
        vals <- as.vector(original_data$logy[, , k])
        vals[!is.na(vals)]
      })

      observed_range <- data.frame(
        biomarker = antigens,
        obs_min = vapply(obs_logy_by_biomarker, function(x) {
          if (length(x) > 0) min(x) else NA_real_
        }, FUN.VALUE = numeric(1)),
        obs_median = vapply(obs_logy_by_biomarker, function(x) {
          if (length(x) > 0) median(x) else NA_real_
        }, FUN.VALUE = numeric(1)),
        obs_max = vapply(obs_logy_by_biomarker, function(x) {
          if (length(x) > 0) max(x) else NA_real_
        }, FUN.VALUE = numeric(1)),
        stringsAsFactors = FALSE
      )
    }
  }

  # Identify issues
  issues <- character(0)

  if (any(validity_check$n_nonfinite > 0)) {
    affected <- validity_check$biomarker[validity_check$n_nonfinite > 0]
    issues <- c(
      issues,
      paste0(
        "Non-finite values detected for biomarker(s): ",
        paste(affected, collapse = ", ")
      )
    )
  }

  if (any(validity_check$n_negative > 0)) {
    affected <- validity_check$biomarker[validity_check$n_negative > 0]
    issues <- c(
      issues,
      paste0(
        "Very low/negative log-scale values detected for biomarker(s): ",
        paste(affected, collapse = ", "),
        " (may indicate prior-data scale mismatch)"
      )
    )
  }

  # Check for scale mismatch with observed data
  if (!is.null(observed_range)) {
    for (i in seq_len(nrow(range_summary))) {
      sim_range <- range_summary$max[i] - range_summary$min[i]
      obs_range <- observed_range$obs_max[i] - observed_range$obs_min[i]

      # If simulated range is much larger than observed (factor of 10+)
      if (is.finite(sim_range) &&
        is.finite(obs_range) &&
        sim_range > obs_range * 10) {
        issues <- c(
          issues,
          paste0(
            "Simulated range for ",
            antigens[i],
            " is much wider than observed data ",
            "(may indicate over-dispersed priors)"
          )
        )
      }
    }
  }

  if (length(issues) == 0) {
    issues <- "No obvious issues detected"
  }

  # Return summary
  to_return <- list(
    n_sims = n_sims,
    validity_check = validity_check,
    range_summary = range_summary,
    observed_range = observed_range,
    issues = issues
  )

  class(to_return) <- c("prior_predictive_summary", "list")

  return(to_return)
}

#' Print method for prior_predictive_summary
#'
#' @param x A `prior_predictive_summary` object
#' @param ... Additional arguments (not used)
#'
#' @returns Invisibly returns `x`
#' @export
print.prior_predictive_summary <- function(x, ...) {
  cli::cli_h1("Prior Predictive Check Summary")

  cli::cli_text("Based on {.strong {x$n_sims}} simulation{?s}")
  cli::cli_text("")

  cli::cli_h2("Validity Check")
  print(x$validity_check)
  cli::cli_text("")

  cli::cli_h2("Simulated Range Summary (log scale)")
  print(x$range_summary)
  cli::cli_text("")

  if (!is.null(x$observed_range)) {
    cli::cli_h2("Observed Data Range (log scale)")
    print(x$observed_range)
    cli::cli_text("")
  }

  cli::cli_h2("Issues Detected")
  for (issue in x$issues) {
    if (issue == "No obvious issues detected") {
      cli::cli_inform(c("v" = issue))
    } else {
      cli::cli_inform(c("!" = issue))
    }
  }

  invisible(x)
}
