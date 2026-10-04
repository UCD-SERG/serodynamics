# Simulate longitudinal case follow-up data from a homogeneous population

Simulate longitudinal case follow-up data from a homogeneous population

## Usage

``` r
sim_case_data(
  n,
  curve_params,
  antigen_isos = get_biomarker_levels(curve_params),
  max_n_obs = 10,
  dist_n_obs = tibble::tibble(n_obs = 1:max_n_obs, prob = 1/max_n_obs),
  followup_interval = 7,
  followup_variance = 1
)
```

## Arguments

- n:

  [integer](https://rdrr.io/r/base/integer.html) number of cases to
  simulate

- curve_params:

  a `curve_params` object from
  [serocalculator::as_curve_params](https://ucd-serg.github.io/serocalculator/reference/as_curve_params.html),
  assumed to be unstratified

- antigen_isos:

  [character](https://rdrr.io/r/base/character.html)
  [vector](https://rdrr.io/r/base/vector.html): which antigen isotypes
  to simulate

- max_n_obs:

  maximum number of observations

- dist_n_obs:

  distribution of number of observations
  ([tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html))

- followup_interval:

  [integer](https://rdrr.io/r/base/integer.html)

- followup_variance:

  [integer](https://rdrr.io/r/base/integer.html)

## Value

a `case_data` object

## Examples

``` r
set.seed(1)
serocalculator::typhoid_curves_nostrat_100 |>
  sim_case_data(n = 100)
#> # A tibble: 3,020 × 11
#>    index_id visit_num timeindays  iter antigen_iso    y0     y1    t1     alpha
#>  * <chr>        <int>      <dbl> <int> <fct>       <dbl>  <dbl> <dbl>     <dbl>
#>  1 1                1          0    83 HlyE_IgA    1.33   50.8   2.60 0.00268  
#>  2 1                1          0    83 HlyE_IgG    3.49  265.    6.08 0.00153  
#>  3 1                1          0    83 LPS_IgA     0.878   4.69  3.06 0.000984 
#>  4 1                1          0    83 LPS_IgG     1.64  300.    2.35 0.000728 
#>  5 1                1          0    83 Vi_IgG      1.30  264.    8.02 0.0000546
#>  6 1                2          7    83 HlyE_IgA    1.33   50.8   2.60 0.00268  
#>  7 1                2          7    83 HlyE_IgG    3.49  265.    6.08 0.00153  
#>  8 1                2          7    83 LPS_IgA     0.878   4.69  3.06 0.000984 
#>  9 1                2          7    83 LPS_IgG     1.64  300.    2.35 0.000728 
#> 10 1                2          7    83 Vi_IgG      1.30  264.    8.02 0.0000546
#> # ℹ 3,010 more rows
#> # ℹ 2 more variables: r <dbl>, value <dbl>
```
