# Marginal within-biomarker variance under the factor model

The Model 2a factor construction is
`par[i,k,p] = mu[k,p] + w[i,k,p] + lambda[k,p] * f[i,p]`, so the
marginal variance of parameter `p` for biomarker `k` is the
within-biomarker variance of `w` plus the squared loading:
\$\$\mathrm{Var}(par\_{k,p}) = (\mathrm{prec.par}\_k^{-1})\_{pp} +
\lambda\_{k,p}^2.\$\$ This pure helper returns that marginal variance
vector for one biomarker, for a single MCMC draw.

## Usage

``` r
marginal_var_2a(prec_par_k, lambda_k)
```

## Arguments

- prec_par_k:

  A `P x P` precision [matrix](https://rdrr.io/r/base/matrix.html) for
  biomarker `k` (the Wishart node `prec.par[k,,]`).

- lambda_k:

  A length-`P` [numeric](https://rdrr.io/r/base/numeric.html)
  [vector](https://rdrr.io/r/base/vector.html) of loadings for biomarker
  `k`.

## Value

A length-`P` [numeric](https://rdrr.io/r/base/numeric.html)
[vector](https://rdrr.io/r/base/vector.html) of marginal variances.
