select_decay_model <- function(file_mod, decay_type) {
  if (!is.null(file_mod)) {
    return(file_mod)
  }

  model_file <- switch(
    decay_type,
    power = "model.jags",
    exponential = "model_exp.jags"
  )

  serodynamics_example(model_file)
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
