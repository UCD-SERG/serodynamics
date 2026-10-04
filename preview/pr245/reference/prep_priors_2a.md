# Prepare priors for Model 2a

Thin wrapper that builds the full Model 2a prior list: it calls
[`prep_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_priors.md)
for the Chapter 1 hyperpriors (`mu.hyp`, `prec.hyp`, `omega`, `wishdf`,
`prec.logy.hyp`, `n_params`) and then appends the factor-loading prior
via
[`add_factor_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/add_factor_priors.md).

Because Model 2a keeps the Chapter 1 priors intact, all Chapter 1 prior
arguments are forwarded unchanged through `...`.

## Usage

``` r
prep_priors_2a(max_antigens, prec_lambda = 0.25, ...)
```

## Arguments

- max_antigens:

  An [integer](https://rdrr.io/r/base/integer.html): number of
  biomarkers (must be \>= 2 for Model 2a, which couples biomarkers).

- prec_lambda:

  Prior precision of the factor loadings (see
  [`add_factor_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/add_factor_priors.md)).
  Default `0.25`.

- ...:

  Additional Chapter 1 prior arguments forwarded to
  [`prep_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_priors.md)
  (e.g. `mu_hyp_param`, `omega_param`, `wishdf_param`).

## Value

A prior [list](https://rdrr.io/r/base/list.html) suitable for
`model_2a.jags`.
