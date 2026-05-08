# Prepare data for Stan

Prepare data for Stan

## Usage

``` r
prep_data_stan(
  dataframe,
  biomarker_column = get_biomarker_names_var(dataframe),
  verbose = FALSE,
  add_newperson = FALSE
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

- add_newperson:

  whether to add an extra record with missing data. **Note:** Stan
  cannot handle NA values in data, so this parameter is currently
  ignored and treated as `FALSE`. Posterior predictive sampling for Stan
  should be done separately using the fitted model object.

## Value

a `prepped_stan_data` object (a [list](https://rdrr.io/r/base/list.html)
with Stan-formatted data)

## Examples

``` r
set.seed(1)
raw_data <-
  serocalculator::typhoid_curves_nostrat_100 |>
  sim_case_data(n = 5)
prepped_data <- prep_data_stan(raw_data)
```
