# Convert loadings + precisions to cross-biomarker correlation

Combines
[`cross_cov_from_loadings()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/cross_cov_from_loadings.md)
and
[`marginal_var_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/marginal_var_2a.md)
to give the same-parameter cross-biomarker correlation for a single MCMC
draw: \$\$\rho_p = c_p /
\sqrt{\mathrm{Var}(par\_{1,p})\\\mathrm{Var}(par\_{2,p})}.\$\$

## Usage

``` r
cross_cor_from_draw_2a(lambda_mat, prec_par_1, prec_par_2)
```

## Arguments

- lambda_mat:

  A `K x P` loadings [matrix](https://rdrr.io/r/base/matrix.html) (rows
  = biomarkers).

- prec_par_1:

  A `P x P` precision [matrix](https://rdrr.io/r/base/matrix.html) for
  biomarker 1.

- prec_par_2:

  A `P x P` precision [matrix](https://rdrr.io/r/base/matrix.html) for
  biomarker 2.

## Value

A length-`P` [numeric](https://rdrr.io/r/base/numeric.html)
[vector](https://rdrr.io/r/base/vector.html) of cross-biomarker
correlations.
