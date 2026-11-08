# Initial-value factory for Model 2a chains

Returns an inits function (of `chain`) for
[`runjags::run.jags()`](https://rdrr.io/pkg/runjags/man/run.jags.html).
It reuses
[`initsfunction()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/initsfunction.md)
for the per-chain RNG seed/name and adds modest starting values for the
new Model 2a nodes:

- `lambda`: small positive starts (the first biomarker's loadings are
  constrained `> 0` in the model, so starts must be positive);

- `mu.par`: started at the hyperprior means. The within-biomarker random
  effects `w` and the factors `f` are left for JAGS to initialise from
  their priors (`N(0, prec.par)` and `N(0,1)`), which is robust.

## Usage

``` r
make_inits_2a(n_antigen_isos, n_params, mu_hyp)
```

## Arguments

- n_antigen_isos:

  [integer](https://rdrr.io/r/base/integer.html) number of biomarkers.

- n_params:

  [integer](https://rdrr.io/r/base/integer.html) number of kinetic
  parameters (5).

- mu_hyp:

  A `n_antigen_isos x n_params`
  [matrix](https://rdrr.io/r/base/matrix.html) of hyperprior means (the
  `mu.hyp` element of the priors).

## Value

A function `f(chain)` returning a list of initial values.
