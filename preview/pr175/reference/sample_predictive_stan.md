# Sample from posterior predictive distribution (Stan models)

Generate posterior predictive samples for new observations using a
fitted Stan model. This function samples from the population-level
parameter distribution and includes measurement error to generate true
posterior predictive samples (not just mean curve draws). Predictions
are made on the original antibody concentration scale.

## Usage

``` r
sample_predictive_stan(
  stan_model_output,
  time_points = c(5, 30, 90),
  n_samples = NULL
)
```

## Arguments

- stan_model_output:

  Output from
  [`run_mod_stan()`](https://ucd-serg.github.io/serodynamics/preview/pr175/reference/run_mod_stan.md),
  an object of class `sr_model` containing the fitted Stan model.
  **Important**: The model must have been fit with `with_post = TRUE` to
  include the posterior draws required for prediction. Note that storing
  posterior draws increases memory usage.

- time_points:

  Numeric vector of time points (in days) at which to generate
  predictions. Default is `c(5, 30, 90)`.

- n_samples:

  Number of posterior samples to draw. If `NULL` (default), uses all
  available posterior samples from the model.

## Value

A list of class `posterior_predictive_stan` containing:

- `samples`: Array of posterior predictive samples with dimensions
  `[n_samples, n_timepoints, n_antigens]`. These include measurement
  error and represent plausible new observations.

- `time_points`: The time points used for prediction

- `summary`: Summary statistics (mean, median, 95% credible intervals)
  for each antigen at each time point

## Details

This function generates true posterior predictive samples by:

1.  Extracting population-level parameter draws (mu_par, prec_logy) from
    the fitted model

2.  Computing the mean log-antibody concentration (mu_logy) directly
    using the Stan model formula for each time point

3.  Adding measurement error sampled from Normal(0, sigma_logy) where
    sigma_logy = 1/sqrt(prec_logy)

4.  Transforming back to the original antibody concentration scale

The resulting samples represent plausible new observations, not just the
mean curve. For stratified models, draws from all strata are combined.

## Examples

``` r
if (FALSE) { # \dontrun{
# Fit a Stan model with posterior samples
model_output <- run_mod_stan(
  data = my_data,
  file_mod = "model.stan",
  nchain = 4,
  with_post = TRUE
)

# Generate posterior predictive samples
predictions <- sample_predictive_stan(
  model_output,
  time_points = c(5, 30, 90)
)

# Access summary statistics
print(predictions$summary)
} # }
```
