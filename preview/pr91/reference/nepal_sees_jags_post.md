# SEES Typhoid run_mod jags output

A
[`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr91/reference/run_mod.md)
output using the
[nepal_sees](https://ucd-serg.github.io/serodynamics/preview/pr91/reference/nepal_sees.md)
example data set as input and stratifying by column `"bldculres"`, which
is the diagnosis type (typhoid or paratyphoid).

## Usage

``` r
nepal_sees_jags_post
```

## Format

### `nepal_sees_jags_post`

A [list](https://rdrr.io/r/base/list.html) consisting of the following
named elements:

- curve_params:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) titled
  `curve_params` that contains the posterior distribution

- attributes:

  A [list](https://rdrr.io/r/base/list.html) of `attributes` that
  summarize the jags inputs

## Source

reference study: <https://doi.org/10.1016/S2666-5247(22)00114-8>
