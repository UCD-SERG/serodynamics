# Prepare priors

Prepare priors

## Usage

``` r
prep_priors(max_antigens)
```

## Arguments

- max_antigens:

  [integer](https://rdrr.io/r/base/integer.html): how many
  antigen-isotypes will be modeled

## Value

a [list](https://rdrr.io/r/base/list.html) with elements: "n_params":
how many parameters??

- "mu.hyp": ??

- "prec.hyp": ??

- "omega" : ??

- "wishdf": Wishart distribution degrees of freedom

- "prec.logy.hyp": array of hyper-parameters for the precision (inverse
  variance) of the biomarkers, on log-scale

## Examples

``` r
prep_priors(max_antigens = 2)
#> $n_params
#> [1] 5
#> 
#> $mu.hyp
#>      [,1] [,2] [,3] [,4] [,5]
#> [1,]    1    7    1   -4   -1
#> [2,]    1    7    1   -4   -1
#> 
#> $prec.hyp
#> , , 1
#> 
#>      [,1] [,2] [,3] [,4] [,5]
#> [1,]    1    0    0    0    0
#> [2,]    1    0    0    0    0
#> 
#> , , 2
#> 
#>      [,1]  [,2] [,3] [,4] [,5]
#> [1,]    0 1e-05    0    0    0
#> [2,]    0 1e-05    0    0    0
#> 
#> , , 3
#> 
#>      [,1] [,2] [,3] [,4] [,5]
#> [1,]    0    0    1    0    0
#> [2,]    0    0    1    0    0
#> 
#> , , 4
#> 
#>      [,1] [,2] [,3]  [,4] [,5]
#> [1,]    0    0    0 0.001    0
#> [2,]    0    0    0 0.001    0
#> 
#> , , 5
#> 
#>      [,1] [,2] [,3] [,4] [,5]
#> [1,]    0    0    0    0    1
#> [2,]    0    0    0    0    1
#> 
#> 
#> $omega
#> , , 1
#> 
#>      [,1] [,2] [,3] [,4] [,5]
#> [1,]    1    0    0    0    0
#> [2,]    1    0    0    0    0
#> 
#> , , 2
#> 
#>      [,1] [,2] [,3] [,4] [,5]
#> [1,]    0   50    0    0    0
#> [2,]    0   50    0    0    0
#> 
#> , , 3
#> 
#>      [,1] [,2] [,3] [,4] [,5]
#> [1,]    0    0    1    0    0
#> [2,]    0    0    1    0    0
#> 
#> , , 4
#> 
#>      [,1] [,2] [,3] [,4] [,5]
#> [1,]    0    0    0   10    0
#> [2,]    0    0    0   10    0
#> 
#> , , 5
#> 
#>      [,1] [,2] [,3] [,4] [,5]
#> [1,]    0    0    0    0    1
#> [2,]    0    0    0    0    1
#> 
#> 
#> $wishdf
#> [1] 20 20
#> 
#> $prec.logy.hyp
#>      [,1] [,2]
#> [1,]    4    1
#> [2,]    4    1
#> 
#> attr(,"class")
#> [1] "curve_params_priors" "list"               
```
