select_decay_model <- function(file_mod, decay_type) {
  default_models <- c(
    power = serodynamics_example("model.jags"),
    exponential = serodynamics_example("model_exp.jags")
  )

  if (is.null(file_mod)) {
    return(unname(default_models[[decay_type]]))
  }

  supplied_path <- normalizePath(
    file_mod,
    mustWork = FALSE
  )
  default_paths <- normalizePath(
    default_models,
    mustWork = FALSE
  )

  supplied_type <- names(default_models)[
    default_paths == supplied_path
  ]

  if (length(supplied_type) == 1 &&
      supplied_type != decay_type) {
    cli::cli_abort(c(
      "{.arg file_mod} is incompatible with {.arg decay_type}.",
      "i" = paste(
        "Omit {.arg file_mod} to select the model",
        "automatically."
      )
    ))
  }

  file_mod
}

configure_decay_priors <- function(priorspec, decay_type) {
  if (decay_type == "power") {
    return(priorspec)
  }

  parameter_index <- seq_len(4)

  priorspec$n_params <- 4L
  priorspec$mu.hyp <- priorspec$mu.hyp[
    , parameter_index, drop = FALSE
  ]
  priorspec$prec.hyp <- priorspec$prec.hyp[
    , parameter_index, parameter_index, drop = FALSE
  ]
  priorspec$omega <- priorspec$omega[
    , parameter_index, parameter_index, drop = FALSE
  ]

  used_priors <- attr(priorspec, "used_priors")

  if (!is.null(used_priors)) {
    used_priors$mu_hyp_param <- used_priors$mu_hyp_param[
      parameter_index
    ]
    used_priors$prec_hyp_param <- used_priors$prec_hyp_param[
      parameter_index
    ]
    used_priors$omega_param <- used_priors$omega_param[
      parameter_index
    ]

    attr(priorspec, "used_priors") <- used_priors
  }

  priorspec
}

get_decay_monitors <- function(decay_type, with_pop_params) {
  parameters <- switch(
    decay_type,
    power = c("y0", "y1", "t1", "alpha", "shape"),
    exponential = c("y0", "y1", "t1", "alpha")
  )

  if (with_pop_params) {
    parameters <- c(
      parameters,
      "mu.par", "prec.par", "prec.logy"
    )
  }

  parameters
}

add_fixed_exponential_shape <- function(jags_final, decay_type) {
  if (decay_type == "power") {
    return(jags_final)
  }

  fixed_shape <- jags_final |>
    dplyr::filter(
      !.data$.is_population_parameter,
      .data$Parameter == "alpha"
    ) |>
    dplyr::mutate(
      Parameter = "shape",
      value = 1
    )

  dplyr::bind_rows(jags_final, fixed_shape)
}
