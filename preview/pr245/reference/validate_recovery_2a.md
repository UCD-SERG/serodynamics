# Validate Model 2a parameter recovery

Simulation-based check that
[`run_mod_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod_2a.md)
recovers a **known** cross-biomarker correlation. It simulates
two-biomarker longitudinal data with a chosen `c_vec`
([`sim_case_data_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/sim_case_data_2a.md)),
fits Model 2a, and returns a table comparing the true cross-biomarker
correlation with the posterior estimate per kinetic parameter.

Recovery is expected to be accurate for well-identified parameters
(peak, decay) and to attenuate gracefully for weakly-identified ones
(baseline); true nulls should yield credible intervals covering zero.

## Usage

``` r
validate_recovery_2a(
  n = 120,
  mu_g = c(0, 3, 2.3, -4, -1),
  mu_a = c(0.2, 3.1, 2.2, -3.8, -1.1),
  sigma_g = diag(c(0.09, 0.16, 0.09, 0.16, 0.09)),
  sigma_a = diag(c(0.09, 0.16, 0.09, 0.16, 0.09)),
  c_vec = c(0.054, 0.08, 0, 0.064, 0),
  noise_sd = 0.15,
  seed = 1,
  ...
)
```

## Arguments

- n:

  [integer](https://rdrr.io/r/base/integer.html) number of subjects.
  Default `120`.

- mu_g, mu_a, sigma_g, sigma_a, c_vec:

  Model 2a truth for
  [`sim_case_data_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/sim_case_data_2a.md).
  Sensible defaults are provided.

- noise_sd:

  Residual SD on the log scale. Default `0.15`.

- seed:

  RNG seed for the simulation. Default `1`.

- ...:

  MCMC controls forwarded to
  [`run_mod_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod_2a.md)
  (e.g. `nchain`, `niter`, `nmc`, `nburn`, `nadapt`).

## Value

A [data.frame](https://rdrr.io/r/base/data.frame.html) with columns
`param`, `true_rho`, `cor_med`, `cor_lo`, `cor_hi`, and `verdict`
("recovered", "null ok", or "review").
