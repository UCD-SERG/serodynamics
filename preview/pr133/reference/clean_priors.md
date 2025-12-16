# Drop legacy/unused prior fields

`clean_priors()` removes elements from a priors list that are not used
by the Kronecker model. This helps avoid passing unused or conflicting
parameters (like `omega`, `wishdf`, or `prec.par`) into JAGS.

## Usage

``` r
clean_priors(x)
```

## Arguments

- x:

  A [`base::list()`](https://rdrr.io/r/base/list.html) of priors (e.g.,
  from
  [`prep_priors()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/prep_priors.md)).

## Value

A [`base::list()`](https://rdrr.io/r/base/list.html) with the legacy
fields removed.

## Author

Kwan Ho Lee

## Examples

``` r
# Example: remove unused fields
priors <- list(
  omega = 1,
  wishdf = 10,
  mu.hyp = matrix(0, 1, 1),
  prec.par = 5
)

cleaned <- clean_priors(priors)
print(names(cleaned))
#> [1] "mu.hyp"
```
