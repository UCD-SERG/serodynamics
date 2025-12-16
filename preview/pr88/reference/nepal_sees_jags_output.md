# SEES Typhoid run_mod jags output

A
[`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr88/reference/run_mod.md)
output using the
[nepal_sees](https://ucd-serg.github.io/serodynamics/preview/pr88/reference/nepal_sees.md)
example data set as input and stratifying by column `"bldculres"`, which
is the diagnosis type (typhoid or paratyphoid). Keeping only IDs
`"newperson"`, `"sees_npl_1"`, `"sees_npl_2"`.

## Usage

``` r
nepal_sees_jags_output
```

## Format

### `nepal_sees_jags_output`

A [list](https://rdrr.io/r/base/list.html) consisting of the following
named elements:

- curve_params:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) titled
  `curve_params` that contains the posterior predictive distribution of
  the person-specific parameters for a "new person" with no observed
  data (`Subject = "newperson"`) and posterior distributions of the
  person-specific parameters for two arbitrarily-chosen subjects
  (`"sees_npl_1"` and `"sees_npl_2"`)

- attributes:

  A [list](https://rdrr.io/r/base/list.html) of `attributes` that
  summarize the jags inputs

## Source

reference study: <https://doi.org/10.1016/S2666-5247(22)00114-8>
