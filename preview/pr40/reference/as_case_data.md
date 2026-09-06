# Convert data into `case_data`

Convert data into `case_data`

## Usage

``` r
as_case_data(
  data,
  id_var = "index_id",
  biomarker_var = "antigen_iso",
  value_var = "value",
  time_in_days = "timeindays"
)
```

## Arguments

- data:

  a [data.frame](https://rdrr.io/r/base/data.frame.html)

- id_var:

  a [character](https://rdrr.io/r/base/character.html) string naming the
  column in `data` denoting participant ID

- biomarker_var:

  a [character](https://rdrr.io/r/base/character.html) string naming the
  column in `data` denoting which biomarker is being reported in
  `value_var` (e.g. "antigen_iso")

- value_var:

  a [character](https://rdrr.io/r/base/character.html) string naming the
  column in `data` with biomarker measurements

- time_in_days:

  a [character](https://rdrr.io/r/base/character.html) string naming the
  column in `data` with elapsed time since seroconversion

## Value

a `case_data` object

## Examples

``` r
set.seed(1)
serocalculator::typhoid_curves_nostrat_100 |>
  sim_case_data(n = 5) |>
  as_case_data(
    id_var = "index_id",
    biomarker_var = "antigen_iso",
    time_in_days = "timeindays",
    value_var = "value"
  )
#> # A tibble: 105 × 11
#>    index_id visit_num timeindays  iter antigen_iso    y0     y1     t1     alpha
#>  * <chr>        <int>      <dbl> <int> <fct>       <dbl>  <dbl>  <dbl>     <dbl>
#>  1 1                1          0    95 HlyE_IgA     1.98   21.9 10.5   0.000600 
#>  2 1                1          0    95 HlyE_IgG     4.45   48.8 10.3   0.00135  
#>  3 1                1          0    95 LPS_IgA      1.39   54.8  2.56  0.000591 
#>  4 1                1          0    95 LPS_IgG     15.6   301.   0.472 0.0000352
#>  5 1                1          0    95 Vi_IgG       3.72 1075.   7.95  0.0000447
#>  6 1                2          8    95 HlyE_IgA     1.98   21.9 10.5   0.000600 
#>  7 1                2          8    95 HlyE_IgG     4.45   48.8 10.3   0.00135  
#>  8 1                2          8    95 LPS_IgA      1.39   54.8  2.56  0.000591 
#>  9 1                2          8    95 LPS_IgG     15.6   301.   0.472 0.0000352
#> 10 1                2          8    95 Vi_IgG       3.72 1075.   7.95  0.0000447
#> # ℹ 95 more rows
#> # ℹ 2 more variables: r <dbl>, value <dbl>
```
