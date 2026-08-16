# Assemble a Model 2a covariance matrix

Builds the `2P x 2P` Model 2a (Chapter 1 + alpha) covariance matrix from
two within-biomarker blocks and a diagonal cross-biomarker block:
\$\$\Sigma = \begin{pmatrix} \Sigma_G & C \\ C^\top & \Sigma_A
\end{pmatrix}, \quad C = \mathrm{diag}(c_1, \ldots, c_P).\$\$ Setting
`c_vec = 0` recovers the Chapter 1 block-diagonal covariance, so Model
2a strictly nests Chapter 1.

This is a small pure helper used by
[`sim_params_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/sim_params_2a.md)
and the tests; it does no model fitting.

## Usage

``` r
build_sigma_2a(sigma_g, sigma_a, c_vec)
```

## Arguments

- sigma_g:

  A `P x P` within-biomarker covariance for biomarker 1 (e.g. IgG). Must
  be symmetric positive-definite.

- sigma_a:

  A `P x P` within-biomarker covariance for biomarker 2 (e.g. IgA). Must
  be symmetric positive-definite.

- c_vec:

  A length-`P` [numeric](https://rdrr.io/r/base/numeric.html)
  [vector](https://rdrr.io/r/base/vector.html) of same-parameter
  cross-biomarker covariances (the diagonal of `C`).

## Value

A `2P x 2P` symmetric covariance
[matrix](https://rdrr.io/r/base/matrix.html). Errors if the result is
not positive-definite (i.e. the requested cross-covariances are too
large).
