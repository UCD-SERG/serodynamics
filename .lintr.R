extra_undesirable_functions <- list(
  # Base messaging
  "message" = "use cli::cli_inform()",
  "warning" = "use cli::cli_warn()",
  "stop" = "use cli::cli_abort()",
  # rlang messaging
  "inform" = "use cli::cli_inform()",
  "warn" = "use cli::cli_warn()",
  "abort" = "use cli::cli_abort()",
  # older cli
  "cli_alert_danger" = "use cli::cli_inform()",
  "cli_alert_info" = "use cli::cli_inform()",
  "cli_alert_success" = "use cli::cli_inform()",
  "cli_alert_warning" = "use cli::cli_inform()"
)

linters <- linters_with_defaults(
  return_linter = NULL,
  trailing_whitespace_linter = NULL,
  pipe_consistency_linter(pipe = "|>"),
  undesirable_function_linter(
    fun = c(default_undesirable_functions, extra_undesirable_functions),
    symbol_is_undesirable = TRUE
  )
)

rm(extra_undesirable_functions) # prevents a warning from lintr:::read_settings

exclusions <- list(
  `data-raw` = list(
    undesirable_function_linter = Inf
  )
)
