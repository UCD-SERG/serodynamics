# Get path to an example file

The
[serodynamics](https://ucd-serg.github.io/serodynamics/preview/pr105/reference/serodynamics-package.md)
package comes bundled with a number of sample files in its
`inst/extdata` directory. This `serodynamics_example()` function make
those sample files easy to access.

## Usage

``` r
serodynamics_example(file = NULL)
```

## Arguments

- file:

  Name of file. If `NULL`, the example files will be listed.

## Value

a [character](https://rdrr.io/r/base/character.html) string providing
the path to the file specified by `file`, or a vector or available files
if `file = NULL`.

## Details

Adapted from
[`readr::readr_example()`](https://readr.tidyverse.org/reference/readr_example.html)
following the guidance in
<https://r-pkgs.org/data.html#sec-data-example-path-helper>.

## Examples

``` r
serodynamics_example()
#> [1] "SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv"
#> [2] "model.dobson.jags"                             
#> [3] "model.jags"                                    
serodynamics_example(
  "SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv")
#> /home/runner/work/_temp/Library/serodynamics/extdata/SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv
```
