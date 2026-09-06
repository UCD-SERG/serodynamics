# Get darwin snapshot variant for macOS

Returns "darwin" for macOS, NULL for other platforms (Linux/Windows).
This is used for testthat snapshot testing where macOS produces
different JAGS MCMC output due to platform-specific floating-point
arithmetic and math library implementations, while Linux and Windows
produce identical results.

## Usage

``` r
darwin_variant()
```

## Value

Character string "darwin" on macOS, NULL on other platforms

## Examples

``` r
if (FALSE) { # \dontrun{
darwin_variant()
} # }
```
