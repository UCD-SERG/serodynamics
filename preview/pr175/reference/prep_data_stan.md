# Prepare data for Stan

Prepare data for Stan

## Usage

``` r
prep_data_stan(
  dataframe,
  biomarker_column = get_biomarker_names_var(dataframe),
  verbose = FALSE
)
```

## Arguments

- dataframe:

  a [data.frame](https://rdrr.io/r/base/data.frame.html) containing case
  data

- biomarker_column:

  [character](https://rdrr.io/r/base/character.html) string indicating
  which column contains antigen-isotype names

- verbose:

  whether to produce verbose messaging

## Value

a `prepped_stan_data` object (a [list](https://rdrr.io/r/base/list.html)
with Stan-formatted data)

## See also

[`sample_predictive_stan()`](https:/ucd-serg.github.io/serodynamics/preview/pr175/reference/sample_predictive_stan.md)
for posterior predictive sampling with Stan models

## Examples

``` r
set.seed(1)
raw_data <-
  serocalculator::typhoid_curves_nostrat_100 |>
  sim_case_data(n = 5)
prepped_data <- prep_data_stan(raw_data)
```
