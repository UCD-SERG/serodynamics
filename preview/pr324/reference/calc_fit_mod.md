# Calculates fitted and residual values for modeled outputs

`calc_fit_mod()` takes antibody kinetic parameter estimates and
calculates fitted and residual values. Fitted values correspond to the
estimated assay value (ex. ELISA units etc.) at time since infection
(TSI). Residual values are calculated as the difference between fitted
and observed values.

## Usage

``` r
calc_fit_mod(
  modeled_dat,
  original_data,
  strat = NA,
  min_value = 0.01,
  decay_type = "power"
)
```

## Arguments

- modeled_dat:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) of modeled
  antibody kinetic parameter values.

- original_data:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) of the original
  input dataset.

- strat:

  A [character](https://rdrr.io/r/base/character.html) string specifying
  the stratification variable name, or
  [NA](https://rdrr.io/r/base/NA.html) if no stratification is used.

- min_value:

  [numeric](https://rdrr.io/r/base/numeric.html); minimum value
  substituted in before taking
  [`log10()`](https://rdrr.io/r/base/Log.html) of `fitted`/observed
  values, to avoid `-Inf` from `log10(0)` when computing
  `log_residual*`.

- decay_type:

  A [character](https://rdrr.io/r/base/character.html) string specifying
  the decay function (`"power"` or `"exponential"`). Passed through to
  `ab()`. Default is `"power"`.

## Value

A [data.frame](https://rdrr.io/r/base/data.frame.html) attached as an
[attributes](https://rdrr.io/r/base/attributes.html) with the following
values:

- Subject = ID number specifying an individual

- Iso_type = The modeled antigen_isotype

- Stratification = The variable used to stratify the model (`"None"`
  when no stratification is used)

- t = Time since infection

- fitted = The median (across posterior draws) fitted value for a given
  `t`

- residual = The median (across posterior draws) residual, calculated as
  the difference between observed and fitted values for a given `t`

- residual_low, residual_high = The 2.5% and 97.5% quantiles (across
  posterior draws) of the residual, giving a precision interval around
  `residual`

- log_residual, log_residual_low, log_residual_high = As `residual`,
  `residual_low`, and `residual_high`, but computed on the log10 scale
  (i.e. `log10(observed) - log10(fitted)`, with values floored at
  `min_value` beforehand)
