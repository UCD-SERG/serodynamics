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

get_model_decay_type <- function(model) {
  decay_type <- attr(model, "decay_type")

  if (is.null(decay_type)) {
    return("power")
  }

  match.arg(decay_type, c("power", "exponential"))
}
