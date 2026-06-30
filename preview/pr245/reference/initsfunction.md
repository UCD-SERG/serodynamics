# JAGS chain initialization function

JAGS chain initialization function

## Usage

``` r
initsfunction(chain)
```

## Arguments

- chain:

  an [integer](https://rdrr.io/r/base/integer.html) specifying which
  chain to initialize

## Value

a [list](https://rdrr.io/r/base/list.html) of RNG seeds and names

## Examples

``` r
initsfunction(1)
#> $.RNG.seed
#> [1] 1
#> 
#> $.RNG.name
#> [1] "base::Wichmann-Hill"
#> 
```
