# Safe inits for the Kronecker model

`inits_kron()` wraps a base initializer (if provided) and makes sure
that legacy pieces (`prec.par`) and Kronecker precision terms (`TauB`,
`TauP`) are not preset. This avoids conflicts when running the
multi-biomarker Kronecker model.

## Usage

``` r
inits_kron(chain, base_inits = NULL)
```

## Arguments

- chain:

  Integer chain index passed through to the base inits function.

- base_inits:

  A function with signature `function(chain)` that returns a named list
  of initial values. Defaults to a simple RNG seed initializer.

## Value

A [`base::list()`](https://rdrr.io/r/base/list.html) of inits suitable
for runjags.

## Author

Kwan Ho Lee

## Examples

``` r
# Basic usage with default RNG initializer
inits_kron(1)
#> $.RNG.name
#> [1] "base::Mersenne-Twister"
#> 
#> $.RNG.seed
#> [1] 124
#> 

# Using a custom base initializer
custom_inits <- function(chain) {
  list(.RNG.name = "base::Wichmann-Hill",
       .RNG.seed = 100 + chain,
       extra = "foo")
}
inits_kron(2, base_inits = custom_inits)
#> $.RNG.name
#> [1] "base::Wichmann-Hill"
#> 
#> $.RNG.seed
#> [1] 102
#> 
#> $extra
#> [1] "foo"
#> 
```
