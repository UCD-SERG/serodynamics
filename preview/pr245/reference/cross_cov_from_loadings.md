# Convert factor loadings to cross-biomarker covariance

In the Model 2a factor parameterization, the same-parameter
cross-biomarker covariance for biomarkers 1 and 2 is the product of
their loadings: \$\$c_p = \lambda\_{1,p}\\\lambda\_{2,p}.\$\$ This pure
helper computes `c_p` for one MCMC draw (or any single set of loadings).
It contains no fitting logic and is trivial to unit-test.

## Usage

``` r
cross_cov_from_loadings(lambda_mat)
```

## Arguments

- lambda_mat:

  A `K x P` [matrix](https://rdrr.io/r/base/matrix.html) of loadings,
  rows = biomarkers, columns = kinetic parameters. Only the first two
  rows are used (Model 2a pairs two biomarkers).

## Value

A length-`P` [numeric](https://rdrr.io/r/base/numeric.html)
[vector](https://rdrr.io/r/base/vector.html) of cross-biomarker
covariances.
