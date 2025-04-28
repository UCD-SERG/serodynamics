test_that(
  desc = "plot_predicted_curve() works with run_mod output and on-the-fly dataset",
  code = {
    skip_if(getRversion() < "4.4.1")
    
    # 1. Build the full dataset exactly as in your example:
    dataset <- nepal_sees |>
      as_case_data(
        id_var        = "person_id",
        biomarker_var = "antigen_iso",
        value_var     = "value",
        time_in_days  = "timeindays"
      ) |>
      rename(
        strat       = bldculres,
        timeindays  = dayssincefeveronset,
        value       = result
      )
    
    # 2. Extract only the subject+antigen you want to overlay as 'dat'
    dat <- dataset |>
      filter(
        id         == "sees_npl_128",
        antigen_iso == "HlyE_IgA"
      )
    
    # 3. Fit the model via run_mod()
    model <- run_mod(
      data          = dataset,
      file_mod      = serodynamics_example("model.jags"),
      nchain        = 2,
      nadapt        = 100,
      nburn         = 100,
      nmc           = 500,
      niter         = 1000,
      strat         = "strat",
      include_subs  = TRUE
    )
    
    # 4. Pull out the full MCMC samples for that one ID + antigen
    full_samples <- process_jags_samples(
      jags_post   = model,
      dataset     = dataset,
      id          = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # 5a. Plot (linear axes) with both model curves + observed points
    plot1 <- plot_predicted_curve(
      param_medians_wide = full_samples,
      dat                = dat,
      legend_obs         = "Observed Data",
      legend_mod1        = "Full Model Predictions",
      show_quantiles     = TRUE,
      log_scale          = FALSE,
      log_x              = FALSE,
      show_all_curves    = TRUE
    )
    expect_true(ggplot2::is.ggplot(plot1))
    vdiffr::expect_doppelganger("predicted_curve_linear", plot1)
    
    # 5b. Plot (log10 axes) with both model curves + observed points
    plot2 <- plot_predicted_curve(
      param_medians_wide = full_samples,
      dat                = dat,
      legend_obs         = "Observed Data",
      legend_mod1        = "Full Model Predictions",
      show_quantiles     = TRUE,
      log_scale          = TRUE,
      log_x              = FALSE,
      show_all_curves    = TRUE
    )
    expect_true(ggplot2::is.ggplot(plot2))
    vdiffr::expect_doppelganger("predicted_curve_log", plot2)
  }
)
