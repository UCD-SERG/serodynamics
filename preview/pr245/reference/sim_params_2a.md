# Simulate subject-level parameters with a known Model 2a covariance

Draws `n` subjects' log-scale kinetic parameters for **two** biomarkers
from a Model 2a multivariate normal: full within-biomarker blocks
`Sigma_G`, `Sigma_A` plus a diagonal cross-biomarker block
`C = diag(c_vec)` (assembled by
[`build_sigma_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/build_sigma_2a.md)).
This gives ground-truth correlated parameters for validating
[`run_mod_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod_2a.md).

The parameter order matches `model.jags`: 1 = log(y0), 2 = log(y1 - y0),
3 = log(t1), 4 = log(alpha), 5 = log(shape - 1). Uses a base-R Cholesky
draw (no extra dependency).

## Usage

``` r
sim_params_2a(n, mu_g, mu_a, sigma_g, sigma_a, c_vec, seed = NULL)
```

## Arguments

- n:

  [integer](https://rdrr.io/r/base/integer.html) number of subjects.

- mu_g, mu_a:

  Length-`P` log-scale mean vectors for biomarker 1 / 2.

- sigma_g, sigma_a:

  `P x P` within-biomarker covariances.

- c_vec:

  Length-`P` same-parameter cross-biomarker covariances.

- seed:

  Optional RNG seed.

## Value

A [list](https://rdrr.io/r/base/list.html) with:

- `log_par`: an `n x (2P)` [matrix](https://rdrr.io/r/base/matrix.html)
  of draws, columns ordered `G1..GP, A1..AP`;

- `sigma`: the `2P x 2P` true covariance;

- `rho`: the length-`P` true cross-biomarker correlations.
