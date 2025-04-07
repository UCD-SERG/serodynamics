

undesirable_functions <- 
  lintr::default_undesirable_functions |> 
  lintr::modify_defaults(
    
  # following https://github.com/r-lib/devtools/blob/2aa51ef/.lintr.R:
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
  "cli_alert_warning" = "use cli::cli_inform()",
  
  library = 
    paste(
      "\nuse `::`, `usethis::use_import_from()`, or `withr::local_package()`",
      "instead of modifying the global search path.",
      "\nSee:\n",
      "<https://r-pkgs.org/code.html#sec-code-r-landscape> and\n",
      "<https://r-pkgs.org/testing-design.html#sec-testing-design-self-contained>",
      "\nfor more details"),
  
  structure = NULL
  
)

linters <- linters_with_defaults(
  return_linter = NULL,
  trailing_whitespace_linter = NULL,
  pipe_consistency_linter(pipe = "|>"),
  undesirable_function_linter(
    fun = undesirable_functions,
    symbol_is_undesirable = TRUE
  )
)

# prevent warnings from lintr::read_settings:
rm(undesirable_functions)

exclusions <- list(
  `data-raw` = list(
    undesirable_function_linter = Inf
  )
)
