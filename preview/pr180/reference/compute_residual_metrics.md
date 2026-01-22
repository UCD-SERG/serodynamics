# Compute Residual-Based Metrics for Posterior Predictions

Computes residuals between observed antibody measurements and posterior
predicted values at observed timepoints. Returns pointwise residuals
and/or summary metrics (MAE, RMSE, SSE) at multiple aggregation levels.

This function provides quantitative posterior predictive diagnostics to
complement visual assessments from
[`plot_predicted_curve()`](https:/ucd-serg.github.io/serodynamics/preview/pr180/reference/plot_predicted_curve.md).
It evaluates how well the model predictions match observed data at the
individual level.

## Usage

``` r
compute_residual_metrics(
  model,
  dataset,
  ids,
  antigen_iso,
  scale = c("original", "log"),
  summary_level = c("id_antigen", "pointwise", "antigen", "overall")
)
```

## Arguments

- model:

  An `sr_model` object (returned by
  [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr180/reference/run_mod.md))
  containing samples from the posterior distribution of the model
  parameters.

- dataset:

  A [dplyr::tbl_df](https://dplyr.tidyverse.org/reference/tbl_df.html)
  with observed antibody response data. Must contain:

  - `id`: participant ID

  - `timeindays` (or the time variable specified in the dataset
    attributes)

  - `value` (or the value variable specified in the dataset attributes)

  - `antigen_iso`: antigen-isotype combination

- ids:

  Character vector of participant IDs to compute residuals for.

- antigen_iso:

  The antigen isotype (e.g., "HlyE_IgA" or "HlyE_IgG").

- scale:

  Character string specifying the scale for residual computation.
  Options:

  - `"original"`: Compute residuals on the original measurement scale
    (default).

  - `"log"`: Compute residuals on the log scale, i.e.,
    `log(obs) - log(pred_med)`. Non-positive values are removed with a
    warning.

- summary_level:

  Character string specifying the aggregation level for summary metrics.
  Options:

  - `"pointwise"`: Return one row per observation with individual
    residuals (no summary).

  - `"id_antigen"`: Summary metrics per `id × antigen_iso` combination
    (default).

  - `"antigen"`: Summary metrics per `antigen_iso` (aggregated across
    IDs).

  - `"overall"`: Single overall summary across all IDs and antigens.

## Value

A [dplyr::tbl_df](https://dplyr.tidyverse.org/reference/tbl_df.html)
containing:

If `summary_level = "pointwise"`:

- `id`: participant ID

- `antigen_iso`: antigen-isotype combination

- `t`: time in days

- `obs`: observed value

- `pred_med`: posterior median prediction

- `pred_lower`: 2.5% quantile of posterior predictions

- `pred_upper`: 97.5% quantile of posterior predictions

- `residual`: raw residual (`obs - pred_med`)

- `abs_residual`: absolute residual (`abs(obs - pred_med)`)

- `sq_residual`: squared residual (`(obs - pred_med)^2`)

If `summary_level` is `"id_antigen"`, `"antigen"`, or `"overall"`:

- `id`: participant ID (if applicable to summary level)

- `antigen_iso`: antigen-isotype combination (if applicable)

- `MAE`: mean absolute error

- `RMSE`: root mean squared error

- `SSE`: sum of squared errors

- `n_obs`: number of observations used in calculation

## Examples

``` r
sees_model <- serodynamics::nepal_sees_jags_output
sees_data <- serodynamics::nepal_sees

# Example 1: Pointwise residuals for a single ID
pointwise_resid <- compute_residual_metrics(
  model = sees_model,
  dataset = sees_data,
  ids = "sees_npl_128",
  antigen_iso = "HlyE_IgA",
  scale = "original",
  summary_level = "pointwise"
)
print(pointwise_resid)
#> # A tibble: 5 × 10
#>   id           antigen_iso     t   obs pred_med pred_lower pred_upper residual
#>   <chr>        <chr>       <dbl> <dbl>    <dbl>      <dbl>      <dbl>    <dbl>
#> 1 sees_npl_128 HlyE_IgA       29 243.     340.       115.      1775.     -96.9
#> 2 sees_npl_128 HlyE_IgA       83 222.     245.       103.      1026.     -22.7
#> 3 sees_npl_128 HlyE_IgA      161 129.     171.        80.9      509.     -42.2
#> 4 sees_npl_128 HlyE_IgA      459  19.8     61.9       22.1      120.     -42.1
#> 5 sees_npl_128 HlyE_IgA      552  25.1     49.0       13.7       94.8    -23.9
#> # ℹ 2 more variables: abs_residual <dbl>, sq_residual <dbl>

# Example 2: Summary metrics per ID × antigen_iso (default)
summary_per_id <- compute_residual_metrics(
  model = sees_model,
  dataset = sees_data,
  ids = "sees_npl_128",
  antigen_iso = "HlyE_IgA",
  scale = "original"
)
print(summary_per_id)
#> # A tibble: 1 × 6
#>   id           antigen_iso   MAE  RMSE    SSE n_obs
#>   <chr>        <chr>       <dbl> <dbl>  <dbl> <int>
#> 1 sees_npl_128 HlyE_IgA     45.6  53.0 14028.     5

# Example 3: Multiple IDs with summary per ID
multi_id_summary <- compute_residual_metrics(
  model = sees_model,
  dataset = sees_data,
  ids = c("sees_npl_128", "sees_npl_131"),
  antigen_iso = "HlyE_IgA",
  scale = "original",
  summary_level = "id_antigen"
)
print(multi_id_summary)
#> # A tibble: 2 × 6
#>   id           antigen_iso   MAE  RMSE    SSE n_obs
#>   <chr>        <chr>       <dbl> <dbl>  <dbl> <int>
#> 1 sees_npl_128 HlyE_IgA     45.6  53.0 14028.     5
#> 2 sees_npl_131 HlyE_IgA     73.5  99.3 49280.     5

# Example 4: Overall summary across multiple IDs
overall_summary <- compute_residual_metrics(
  model = sees_model,
  dataset = sees_data,
  ids = c("sees_npl_128", "sees_npl_131"),
  antigen_iso = "HlyE_IgA",
  scale = "original",
  summary_level = "overall"
)
print(overall_summary)
#> # A tibble: 1 × 4
#>     MAE  RMSE    SSE n_obs
#>   <dbl> <dbl>  <dbl> <int>
#> 1  59.5  79.6 63308.    10

# Example 5: Log-scale residuals
log_resid <- compute_residual_metrics(
  model = sees_model,
  dataset = sees_data,
  ids = "sees_npl_128",
  antigen_iso = "HlyE_IgA",
  scale = "log",
  summary_level = "id_antigen"
)
print(log_resid)
#> # A tibble: 1 × 6
#>   id           antigen_iso   MAE  RMSE   SSE n_obs
#>   <chr>        <chr>       <dbl> <dbl> <dbl> <int>
#> 1 sees_npl_128 HlyE_IgA    0.505 0.624  1.95     5
```
