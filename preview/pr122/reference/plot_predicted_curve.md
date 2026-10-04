# Generate Predicted Antibody Response Curves (Median + 95% CI)

Plots a median antibody response curve with a 95% credible interval
ribbon, using MCMC samples from the posterior distribution. Optionally
overlays observed data, applies logarithmic spacing on the y- and
x-axes, and shows all individual sampled curves.

## Usage

``` r
plot_predicted_curve(
  sr_model,
  ids,
  antigen_iso,
  dataset = NULL,
  legend_obs = "Observed data",
  legend_median = "Median prediction",
  show_quantiles = TRUE,
  log_y = FALSE,
  log_x = FALSE,
  show_all_curves = FALSE,
  alpha_samples = 0.3,
  xlim = NULL,
  ylab = NULL,
  facet_by_id = NULL,
  ncol = NULL
)
```

## Arguments

- sr_model:

  An `sr_model` object (returned by
  [`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr122/reference/run_mod.md))
  containing samples from the posterior distribution of the model
  parameters.

- ids:

  The participant IDs to plot; for example, `"sees_npl_128"`.

- antigen_iso:

  The antigen isotype to plot; for example, "HlyE_IgA" or "HlyE_IgG".

- dataset:

  (Optional) A
  [dplyr::tbl_df](https://dplyr.tidyverse.org/reference/tbl_df.html)
  with observed antibody response data. Must contain:

  - `timeindays`

  - `value`

  - `id`

  - `antigen_iso`

- legend_obs:

  Label for observed data in the legend.

- legend_median:

  Label for the median prediction line.

- show_quantiles:

  [logical](https://rdrr.io/r/base/logical.html); if
  [TRUE](https://rdrr.io/r/base/logical.html) (default), plots the 2.5%,
  50%, and 97.5% quantiles.

- log_y:

  [logical](https://rdrr.io/r/base/logical.html); if
  [TRUE](https://rdrr.io/r/base/logical.html), applies a
  [log10](https://rdrr.io/r/base/Log.html) transformation to the y-axis.

- log_x:

  [logical](https://rdrr.io/r/base/logical.html); if
  [TRUE](https://rdrr.io/r/base/logical.html), applies a
  [log10](https://rdrr.io/r/base/Log.html) transformation to the x-axis.

- show_all_curves:

  [logical](https://rdrr.io/r/base/logical.html); if
  [TRUE](https://rdrr.io/r/base/logical.html), overlays all individual
  sampled curves.

- alpha_samples:

  Numeric; transparency level for individual curves (default = 0.3).

- xlim:

  (Optional) A numeric vector of length 2 providing custom x-axis
  limits.

- ylab:

  (Optional) A string for the y-axis label. If `NULL` (default), the
  label is automatically set to "ELISA units" or "ELISA units (log
  scale)" based on the `log_y` argument.

- facet_by_id:

  [logical](https://rdrr.io/r/base/logical.html); if
  [TRUE](https://rdrr.io/r/base/logical.html), facets the plot by 'id'.
  Defaults to [TRUE](https://rdrr.io/r/base/logical.html) when multiple
  IDs are provided.

- ncol:

  [integer](https://rdrr.io/r/base/integer.html); number of columns for
  faceting.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object displaying predicted antibody response curves with a median curve
and a 95% credible interval band as default.

## Examples

``` r
# 1) Prepare the on-the-fly dataset
dataset <- serodynamics::nepal_sees |>
  as_case_data(
    id_var        = "id",
    biomarker_var = "antigen_iso",
    value_var     = "value",
    time_in_days  = "timeindays"
  ) |>
  dplyr::rename(
    strat      = bldculres,
    timeindays = dayssincefeveronset,
    value      = result
  )

# 2) Extract just the one subject/antigen for overlay later
dat <- dataset |>
  dplyr::filter(id == "sees_npl_128", antigen_iso == "HlyE_IgA")

# 3) Load the pre-computed model output included with the package.
# This is much faster than running the model live.
model <- serodynamics::nepal_sees_jags_output


# 4a) Plot (linear axes) with all individual curves + median ribbon
p1 <- plot_predicted_curve(
  sr_model           = model,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  dataset            = dat,
  legend_obs         = "Observed data",
  legend_median        = "Median prediction",
  show_quantiles     = TRUE,
  log_y          = FALSE,
  log_x              = FALSE,
  show_all_curves    = TRUE
)
print(p1)


# 4b) Plot (log10 y-axis) with all individual curves + median ribbon
p2 <- plot_predicted_curve(
  sr_model           = model,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  dataset            = dat,
  legend_obs         = "Observed data",
  legend_median        = "Median prediction",
  show_quantiles     = TRUE,
  log_y          = TRUE,
  log_x              = FALSE,
  show_all_curves    = TRUE
)
print(p2)


# 4c) Plot with custom x-axis limits (0-600 days)
p3 <- plot_predicted_curve(
  sr_model           = model,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  dataset            = dat,
  legend_obs         = "Observed data",
  legend_median        = "Median prediction",
  show_quantiles     = TRUE,
  log_y          = FALSE,
  log_x              = FALSE,
  show_all_curves    = TRUE,
  xlim               = c(0, 600)
)
print(p3)


# 5) Multi-ID, faceted plot (single antigen)
ids <- c("sees_npl_128", "sees_npl_131")
antigen <- "HlyE_IgA"

dat_multi <- dataset |>
  dplyr::filter(id %in% ids, antigen_iso == antigen)

p4 <- plot_predicted_curve(
  sr_model        = model,
  id              = ids,
  antigen_iso     = antigen,
  dataset         = dat_multi,
  show_all_curves = TRUE,
  facet_by_id     = TRUE
)
print(p4)
```
