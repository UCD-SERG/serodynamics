# Validate the Chapter 1 nesting / no-false-positive behaviour

Complementary check to
[`validate_recovery_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/validate_recovery_2a.md).
It simulates **independent** two-biomarker data (all cross-biomarker
covariances `c_vec = 0`, i.e. the Chapter 1 truth) and confirms that
Model 2a does **not** invent cross-biomarker correlation: every
posterior `c_p` credible interval should cover zero. This is the
empirical counterpart of the algebraic fact that `lambda = 0` reduces
Model 2a to Chapter 1.

The packaged typhoid simulator
[`sim_case_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/sim_case_data.md)
also produces independent biomarkers, so fitting Model 2a to its output
is an equivalent real-data-style null check.

## Usage

``` r
validate_nesting_2a(
  n = 120,
  mu_g = c(0, 3, 2.3, -4, -1),
  mu_a = c(0.2, 3.1, 2.2, -3.8, -1.1),
  sigma_g = diag(c(0.09, 0.16, 0.09, 0.16, 0.09)),
  sigma_a = diag(c(0.09, 0.16, 0.09, 0.16, 0.09)),
  noise_sd = 0.15,
  seed = 1,
  ...
)
```

## Arguments

- n:

  [integer](https://rdrr.io/r/base/integer.html) number of subjects.
  Default `120`.

- mu_g, mu_a, sigma_g, sigma_a:

  Model 2a truth (cross-block forced to zero).

- noise_sd:

  Residual SD on the log scale. Default `0.15`.

- seed:

  RNG seed. Default `1`.

- ...:

  MCMC controls forwarded to
  [`run_mod_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod_2a.md).

## Value

A [data.frame](https://rdrr.io/r/base/data.frame.html) with columns
`param`, `cov_med`, `cov_lo`, `cov_hi`, and `covers_zero`
([logical](https://rdrr.io/r/base/logical.html)); all rows should have
`covers_zero = TRUE`.
