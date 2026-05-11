# Sample from posterior predictive distribution (Stan models)

Generate posterior predictive samples for new observations using a
fitted Stan model. This function samples from the marginal posterior
distribution of model parameters to generate predictions for specified
time points using the antibody dynamic curve model.

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
  [`run_mod_stan()`](https:/ucd-serg.github.io/serodynamics/preview/pr175/reference/run_mod_stan.md),
  an object of class `sr_model` containing the fitted Stan model

- time_points:

  Numeric vector of time points (in days) at which to generate
  predictions. Default is `c(5, 30, 90)`.

- n_samples:

  Number of posterior samples to draw. If `NULL` (default), uses all
  available posterior samples from the model.

## Value

A list of class `posterior_predictive_stan` containing:

- samples:

  Array of posterior predictive samples with dimensions
  `[n_samples, n_timepoints, n_antigens]`

- time_points:

  The time points used for prediction

- summary:

  Summary statistics (mean, median, 95\\ for each antigen at each time
  point

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
