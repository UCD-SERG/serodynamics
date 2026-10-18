# Build stable JAGS chain initial values

Build stable JAGS chain initial values

## Usage

``` r
build_chain_inits(longdata, chain, n_params)
```

## Arguments

- longdata:

  A `prepped_jags_data` [list](https://rdrr.io/r/base/list.html) as
  returned by
  [`prep_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr322/reference/prep_data.md).
  It must include `nsubj` and `n_antigen_isos`.

- chain:

  An [integer](https://rdrr.io/r/base/integer.html) chain index between
  1 and 4.

- n_params:

  An [integer](https://rdrr.io/r/base/integer.html) giving the number of
  subject-level parameters in the selected JAGS model. Supported values
  are 4 (exponential decay) and 5 (power decay).

  The returned `par` array follows the JAGS model layout:
  `par[, , 1] = log(y0)`, `par[, , 2] = log(y1 - y0)`,
  `par[, , 3] = log(t1)`, `par[, , 4] = log(alpha)`, and, for the
  power-decay model only, `par[, , 5] = log(shape - 1)`. Slices 4 and 5
  are initialized to fixed log-scale values so that the piecewise
  recovery expression stays numerically valid during JAGS' initial-value
  checks across platforms.

## Value

A [list](https://rdrr.io/r/base/list.html) suitable for the `inits`
argument of
[`runjags::run.jags()`](https://rdrr.io/pkg/runjags/man/run.jags.html),
containing `.RNG.seed`, `.RNG.name`, and a `par` array with dimensions
`nsubj x n_antigen_isos x n_params`.
