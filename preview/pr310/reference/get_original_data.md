# Uses original data from correct source for `plot_residuals()`

`get_original_data` will be used when a `facet_by_strat` or
`color_by_strat` is called in order to access the stratifying variable.
When the stratified variable occurs in the original
[`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr310/reference/run_serodynamics.md)
call, the `original_data` attached to the output will be used. If the
stratification was not used in the
[`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr310/reference/run_serodynamics.md)
call, then the `original_data` will need to be attached as an option.

## Usage

``` r
get_original_data(
  model,
  original_data = NULL,
  strat = attr(model, "strat"),
  color_strat = FALSE,
  color_by_strat = NULL,
  facet_strat = FALSE,
  facet_by_strat = NULL
)
```
