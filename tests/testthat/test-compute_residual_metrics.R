test_that(
  desc = "compute_residual_metrics() returns pointwise residuals correctly",
  code = {
    # Use package data
    sr_model <- serodynamics::nepal_sees_jags_output
    dataset <- serodynamics::nepal_sees
    
    # Compute pointwise residuals for a single ID
    result <- compute_residual_metrics(
      model = sr_model,
      dataset = dataset,
      ids = "sees_npl_128",
      antigen_iso = "HlyE_IgA",
      scale = "original",
      summary_level = "pointwise"
    )
    
    # Check structure
    expect_s3_class(result, "tbl_df")
    expect_true(all(c("id", "antigen_iso", "t", "obs", "pred_med",
                      "pred_lower", "pred_upper", "residual",
                      "abs_residual", "sq_residual") %in% names(result)))
    
    # Check dimensions
    # Count observed data points for this ID and antigen
    obs_count <- dataset |>
      dplyr::filter(
        id == "sees_npl_128",
        antigen_iso == "HlyE_IgA"
      ) |>
      nrow()
    
    expect_equal(nrow(result), obs_count)
    
    # Check that residuals are computed correctly
    expect_equal(result$residual, result$obs - result$pred_med)
    expect_equal(result$abs_residual, abs(result$residual))
    expect_equal(result$sq_residual, result$residual^2)
    
    # Check no missing values in key columns
    expect_false(any(is.na(result$obs)))
    expect_false(any(is.na(result$pred_med)))
    expect_false(any(is.na(result$residual)))
  }
)

test_that(
  desc = "compute_residual_metrics() returns id_antigen summary correctly",
  code = {
    sr_model <- serodynamics::nepal_sees_jags_output
    dataset <- serodynamics::nepal_sees
    
    # Compute summary for a single ID
    result <- compute_residual_metrics(
      model = sr_model,
      dataset = dataset,
      ids = "sees_npl_128",
      antigen_iso = "HlyE_IgA",
      scale = "original",
      summary_level = "id_antigen"
    )
    
    # Check structure
    expect_s3_class(result, "tbl_df")
    expect_true(all(c("id", "antigen_iso", "MAE", "RMSE", "SSE", 
                      "n_obs") %in% names(result)))
    
    # Check dimensions
    expect_equal(nrow(result), 1)
    
    # Check that metrics are positive
    expect_true(result$MAE >= 0)
    expect_true(result$RMSE >= 0)
    expect_true(result$SSE >= 0)
    expect_true(result$n_obs > 0)
    
    # Check RMSE is computed correctly from SSE and n_obs
    expect_equal(result$RMSE, sqrt(result$SSE / result$n_obs))
  }
)

test_that(
  desc = "compute_residual_metrics() works with multiple IDs",
  code = {
    sr_model <- serodynamics::nepal_sees_jags_output
    dataset <- serodynamics::nepal_sees
    
    # Compute summary for multiple IDs
    result <- compute_residual_metrics(
      model = sr_model,
      dataset = dataset,
      ids = c("sees_npl_128", "sees_npl_131"),
      antigen_iso = "HlyE_IgA",
      scale = "original",
      summary_level = "id_antigen"
    )
    
    # Check structure
    expect_s3_class(result, "tbl_df")
    expect_equal(nrow(result), 2)
    expect_true(all(result$id %in% c("sees_npl_128", "sees_npl_131")))
    
    # Each ID should have its own metrics
    expect_true(all(c("MAE", "RMSE", "SSE", "n_obs") %in% names(result)))
  }
)

test_that(
  desc = "compute_residual_metrics() computes antigen-level summary",
  code = {
    sr_model <- serodynamics::nepal_sees_jags_output
    dataset <- serodynamics::nepal_sees
    
    # Compute summary aggregated across IDs
    result <- compute_residual_metrics(
      model = sr_model,
      dataset = dataset,
      ids = c("sees_npl_128", "sees_npl_131"),
      antigen_iso = "HlyE_IgA",
      scale = "original",
      summary_level = "antigen"
    )
    
    # Check structure
    expect_s3_class(result, "tbl_df")
    expect_equal(nrow(result), 1)
    expect_true(all(c("antigen_iso", "MAE", "RMSE", "SSE", 
                      "n_obs") %in% names(result)))
    expect_false("id" %in% names(result))
    
    # Check that n_obs is the sum across IDs
    pointwise <- compute_residual_metrics(
      model = sr_model,
      dataset = dataset,
      ids = c("sees_npl_128", "sees_npl_131"),
      antigen_iso = "HlyE_IgA",
      scale = "original",
      summary_level = "pointwise"
    )
    expect_equal(result$n_obs, nrow(pointwise))
  }
)

test_that(
  desc = "compute_residual_metrics() computes overall summary",
  code = {
    sr_model <- serodynamics::nepal_sees_jags_output
    dataset <- serodynamics::nepal_sees
    
    # Compute overall summary
    result <- compute_residual_metrics(
      model = sr_model,
      dataset = dataset,
      ids = c("sees_npl_128", "sees_npl_131"),
      antigen_iso = "HlyE_IgA",
      scale = "original",
      summary_level = "overall"
    )
    
    # Check structure
    expect_s3_class(result, "tbl_df")
    expect_equal(nrow(result), 1)
    expect_true(all(c("MAE", "RMSE", "SSE", "n_obs") %in% names(result)))
    expect_false("id" %in% names(result))
    expect_false("antigen_iso" %in% names(result))
  }
)

test_that(
  desc = "compute_residual_metrics() works with log scale",
  code = {
    sr_model <- serodynamics::nepal_sees_jags_output
    dataset <- serodynamics::nepal_sees
    
    # Compute log-scale residuals
    result <- compute_residual_metrics(
      model = sr_model,
      dataset = dataset,
      ids = "sees_npl_128",
      antigen_iso = "HlyE_IgA",
      scale = "log",
      summary_level = "id_antigen"
    )
    
    # Check structure
    expect_s3_class(result, "tbl_df")
    expect_true(all(c("MAE", "RMSE", "SSE", "n_obs") %in% names(result)))
    
    # Metrics should be positive
    expect_true(result$MAE >= 0)
    expect_true(result$RMSE >= 0)
    expect_true(result$SSE >= 0)
  }
)

test_that(
  desc = "compute_residual_metrics() handles non-positive values in log scale",
  code = {
    sr_model <- serodynamics::nepal_sees_jags_output
    dataset <- serodynamics::nepal_sees
    
    # This should generate a warning if there are non-positive values
    # (which is unlikely in this dataset, but we test the mechanism)
    expect_no_error(
      compute_residual_metrics(
        model = sr_model,
        dataset = dataset,
        ids = "sees_npl_128",
        antigen_iso = "HlyE_IgA",
        scale = "log",
        summary_level = "pointwise"
      )
    )
  }
)

test_that(
  desc = "compute_residual_metrics() errors with no matching data",
  code = {
    sr_model <- serodynamics::nepal_sees_jags_output
    dataset <- serodynamics::nepal_sees
    
    # Try with non-existent ID
    expect_error(
      compute_residual_metrics(
        model = sr_model,
        dataset = dataset,
        ids = "nonexistent_id",
        antigen_iso = "HlyE_IgA",
        scale = "original",
        summary_level = "pointwise"
      ),
      "No observed data found"
    )
  }
)

test_that(
  desc = "compute_residual_metrics() pointwise output matches manual calculation",
  code = {
    sr_model <- serodynamics::nepal_sees_jags_output
    dataset <- serodynamics::nepal_sees
    
    # Get pointwise residuals
    result <- compute_residual_metrics(
      model = sr_model,
      dataset = dataset,
      ids = "sees_npl_128",
      antigen_iso = "HlyE_IgA",
      scale = "original",
      summary_level = "pointwise"
    )
    
    # Manually compute MAE
    manual_mae <- mean(result$abs_residual)
    
    # Get summary
    summary_result <- compute_residual_metrics(
      model = sr_model,
      dataset = dataset,
      ids = "sees_npl_128",
      antigen_iso = "HlyE_IgA",
      scale = "original",
      summary_level = "id_antigen"
    )
    
    # Check that summary MAE matches manual calculation
    expect_equal(summary_result$MAE, manual_mae)
  }
)

test_that(
  desc = "compute_residual_metrics() snapshot test for stability",
  code = {
    withr::local_seed(123)
    
    sr_model <- serodynamics::nepal_sees_jags_output
    dataset <- serodynamics::nepal_sees
    
    # Test pointwise output
    pointwise_result <- compute_residual_metrics(
      model = sr_model,
      dataset = dataset,
      ids = "sees_npl_128",
      antigen_iso = "HlyE_IgA",
      scale = "original",
      summary_level = "pointwise"
    )
    
    expect_snapshot_data(pointwise_result, name = "pointwise-residuals")
    
    # Test summary output
    summary_result <- compute_residual_metrics(
      model = sr_model,
      dataset = dataset,
      ids = c("sees_npl_128", "sees_npl_131"),
      antigen_iso = "HlyE_IgA",
      scale = "original",
      summary_level = "id_antigen"
    )
    
    expect_snapshot_data(summary_result, name = "id-antigen-summary")
  }
)
