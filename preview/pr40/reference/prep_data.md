# prepare data for JAGs

prepare data for JAGs

## Usage

``` r
prep_data(dataframe)
```

## Arguments

- dataframe:

  a [data.frame](https://rdrr.io/r/base/data.frame.html) containing ...

## Value

a `prepped_jags_data` object (a [list](https://rdrr.io/r/base/list.html)
with extra attributes ...)

## Examples

``` r
set.seed(1)
raw_data <-
  serocalculator::typhoid_curves_nostrat_100 |>
  sim_case_data(n = 5)
prepped_data <- prep_data(raw_data)
```
