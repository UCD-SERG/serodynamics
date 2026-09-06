# Calculates fitted and residual values for modeled outputs

`calc_fit_mod()` takes antibody kinetic parameter estimates and
calculates fitted and residual values. Fitted values correspond to the
estimated assay value (ex. ELISA units etc.) at time since infection
(TSI). Residual values are calculated as the difference between fitted
and observed values.

## Usage

``` r
calc_fit_mod(modeled_dat, original_data)
```

## Arguments

- modeled_dat:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) of modeled
  antibody kinetic parameter values.

- original_data:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) of the original
  input dataset.

## Value

A [data.frame](https://rdrr.io/r/base/data.frame.html) attached as an
[attributes](https://rdrr.io/r/base/attributes.html) with the following
values:

- Subject = ID number specifying an individual

- Iso_type = The modeled antigen_isotype

- t = Time since infection

- fitted = The fitted value calculated using model output parameters for
  a given `t`

- residual = The residual value calculated as the difference between
  observed and fitted values for a given `t`
