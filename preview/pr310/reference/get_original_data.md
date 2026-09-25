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

## Arguments

- model:

  An `sr_model` object (returned by
  [`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr310/reference/run_serodynamics.md)),
  with `original_data`, `strat`, and `decay_type` attributes (see
  [`calc_fit_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr310/reference/calc_fit_mod.md)).

- original_data:

  [data.frame](https://rdrr.io/r/base/data.frame.html); the original
  dataset fed into
  [`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr310/reference/run_serodynamics.md).
  Must be included if `facet_by_strat` or `color_by_strat` include a
  variable that was not specified as `strat` in
  [`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr310/reference/run_serodynamics.md).

- strat:

  The stratification specified in the original
  [`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr310/reference/run_serodynamics.md)
  model.

- color_strat:

  The color stratification specified in `facet_by_strat`.

- color_by_strat:

  [character](https://rdrr.io/r/base/character.html); colors residual
  plot by the specified stratification variable. MAE is not calculated
  by this variable. Must include the original data set if not
  stratifying by `strat` variable specified in
  [`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr310/reference/run_serodynamics.md).
  Default `NULL`.

- facet_strat:

  The facet stratification specified in `facet_by_strat`.

- facet_by_strat:

  [character](https://rdrr.io/r/base/character.html); facets residual
  plot and calculates MAE by specified stratification variable. Must
  include the original data set if not stratifying by `strat` variable
  specified in
  [`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr310/reference/run_serodynamics.md).
  Default `NULL`.
