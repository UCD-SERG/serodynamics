# Simulate longitudinal case data with known cross-biomarker covariance

End-to-end simulator for validating Model 2a. It draws correlated
subject-level parameters with
[`sim_params_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/sim_params_2a.md),
evaluates the Chapter 1 two-phase curve
[`ab()`](https://ucd-serg.github.io/serocalculator/latest-tag/reference/ab.html)
at a set of visit times for **two** biomarkers, adds log-normal
measurement noise, and returns a long
[data.frame](https://rdrr.io/r/base/data.frame.html) in the
`serocalculator` case-data layout that
[`prep_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_data.md)
/
[`run_mod_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod_2a.md)
accept.

Decomposed on purpose: the statistical truth lives in
[`sim_params_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/sim_params_2a.md),
the curve in
[`ab()`](https://ucd-serg.github.io/serocalculator/latest-tag/reference/ab.html),
and this function only handles visit times, noise, and reshaping.

## Usage

``` r
sim_case_data_2a(
  n,
  mu_g,
  mu_a,
  sigma_g,
  sigma_a,
  c_vec,
  visit_times = c(0, 7, 14, 28, 56, 90, 140, 200),
  noise_sd = 0.2,
  biomarkers = c("HlyE_IgG", "HlyE_IgA"),
  seed = NULL
)
```

## Arguments

- n:

  [integer](https://rdrr.io/r/base/integer.html) number of subjects.

- mu_g, mu_a, sigma_g, sigma_a, c_vec:

  Model 2a truth, passed to
  [`sim_params_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/sim_params_2a.md).

- visit_times:

  [numeric](https://rdrr.io/r/base/numeric.html) vector of sampling
  times (days) shared by all subjects. Default
  `c(0, 7, 14, 28, 56, 90, 140, 200)`.

- noise_sd:

  Residual SD on the log scale. Default `0.2`.

- biomarkers:

  Length-2 [character](https://rdrr.io/r/base/character.html) biomarker
  labels. Default `c("HlyE_IgG", "HlyE_IgA")`.

- seed:

  Optional RNG seed.

## Value

A [list](https://rdrr.io/r/base/list.html) with `data` (the long
case-data [data.frame](https://rdrr.io/r/base/data.frame.html)) and
`truth` (the
[`sim_params_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/sim_params_2a.md)
output, including `rho`).
