# Prepare priors

Takes multiple [vector](https://rdrr.io/r/base/vector.html) inputs to
allow for modifiable priors. Priors can be specified as an option in
run_mod.

## Usage

``` r
prep_priors(
  max_antigens,
  mu_hyp_param = c(1, 7, 1, -4, -1),
  prec_hyp_param = c(1, 1e-05, 1, 0.001, 1),
  omega_param = c(1, 50, 1, 10, 1),
  wishdf_param = 20,
  prec_logy_hyp_param = c(4, 1)
)
```

## Arguments

- max_antigens:

  An [integer](https://rdrr.io/r/base/integer.html) specifying how many
  antigen-isotypes (biomarkers) will be modeled.

- mu_hyp_param:

  A [numeric](https://rdrr.io/r/base/numeric.html)
  [vector](https://rdrr.io/r/base/vector.html) of 5 values representing
  the prior mean for the population level parameters parameters (y0, y1,
  t1, r, alpha) for each biomarker. If specified, must be 5 values long,
  representing the following parameters:

  - y0 = baseline antibody concentration (default = 1.0)

  - y1 = peak antibody concentration (default = 7.0)

  - t1 = time to peak (default = 1.0)

  - r = shape parameter (default = -4.0)

  - alpha = decay rate (default = -1.0)

- prec_hyp_param:

  A [numeric](https://rdrr.io/r/base/numeric.html)
  [vector](https://rdrr.io/r/base/vector.html) of 5 values corresponding
  to hyperprior diagonal entries for the precision matrix (i.e. inverse
  variance) representing prior covariance of uncertainty around
  `mu_hyp_param`. If specified, must be 5 values long:

  - defaults: y0 = 1.0, y1 = 0.00001, t1 = 1.0, r = 0.001, alpha = 1.0

- omega_param:

  A [numeric](https://rdrr.io/r/base/numeric.html)
  [vector](https://rdrr.io/r/base/vector.html) of 5 values corresponding
  to the diagonal entries representing the Wishart hyperprior
  distributions of `prec_hyp_param`, describing how much we expect
  parameters to vary between individuals. If specified, must be 5 values
  long:

  - defaults: y0 = 1.0, y1 = 50.0, t1 = 1.0, r = 10.0, alpha = 1.0

- wishdf_param:

  An [integer](https://rdrr.io/r/base/integer.html)
  [vector](https://rdrr.io/r/base/vector.html) of 1 value specifying the
  degrees of freedom for the Wishart hyperprior distribution of
  `prec_hyp_param`. If specified, must be 1 value long.

  - default = 20.0

  - The value of `wishdf_param` controls how informative the Wishart
    prior is. Higher values lead to tighter priors on individual
    variation. Lower values (e.g., 5–10) make the prior more weakly
    informative, which can help improve convergence if the model is
    over-regularized.

- prec_logy_hyp_param:

  A [numeric](https://rdrr.io/r/base/numeric.html)
  [vector](https://rdrr.io/r/base/vector.html) of 2 values corresponding
  to hyperprior diagonal entries on the log-scale for the precision
  matrix (i.e. inverse variance) representing prior beliefs of
  individual variation. If specified, must be 2 values long:

  - defaults = 4.0, 1.0

## Value

A "curve_params_priors" object (a subclass of
[list](https://rdrr.io/r/base/list.html) with the inputs to
`prep_priors()` attached as
[attributes](https://rdrr.io/r/base/attributes.html) entry named
`"used_priors"`), containing the following elements:

- "n_params": Corresponds to the 5 parameters being estimated.

- "mu.hyp": A [matrix](https://rdrr.io/r/base/matrix.html) of
  hyperpriors with dimensions `max_antigens` x 5 (# of parameters),
  representing the mean of the hyperprior distribution for the five
  seroresponse parameters: y0, y1, t1, r, and alpha).

- "prec.hyp": A three-dimensional
  [numeric](https://rdrr.io/r/base/numeric.html)
  [array](https://rdrr.io/r/base/array.html) with dimensions
  `max_antigens` x 5 (# of parameters), containing the precision
  matrices of the hyperprior distributions of `mu.hyp`, for each
  biomarker.

- "omega" : A three-dimensional
  [numeric](https://rdrr.io/r/base/numeric.html)
  [array](https://rdrr.io/r/base/array.html) with 5
  [matrix](https://rdrr.io/r/base/matrix.html),each with dimensions
  `max_antigens` x 5 (# of parameters), representing the precision
  matrix of Wishart hyper-priors for `prec.hyp`.

- "wishdf": A [vector](https://rdrr.io/r/base/vector.html) of 2 values
  specifying the degrees of freedom for the Wishart distribution used in
  the subject-level precision prior.

- "prec.logy.hyp": A [matrix](https://rdrr.io/r/base/matrix.html) of
  hyper-parameters for the precision (inverse variance) of individual
  variation measuring `max_antigens` x 2, on the log-scale.

- `used_priors` = inputs to `prep_priors()` attached as attributes.

## Examples

``` r
prep_priors(max_antigens = 2,
            mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
            prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
            omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
            wishdf_param = 20,
            prec_logy_hyp_param = c(4.0, 1.0))
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
#> attr(,"used_priors")
#> attr(,"used_priors")$mu_hyp_param
#> [1]  1  7  1 -4 -1
#> 
#> attr(,"used_priors")$prec_hyp_param
#> [1] 1e+00 1e-05 1e+00 1e-03 1e+00
#> 
#> attr(,"used_priors")$omega_param
#> [1]  1 50  1 10  1
#> 
#> attr(,"used_priors")$wishdf_param
#> [1] 20
#> 
#> attr(,"used_priors")$prec_logy_hyp_param
#> [1] 4 1
#> 

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
#> attr(,"used_priors")
#> attr(,"used_priors")$mu_hyp_param
#> [1]  1  7  1 -4 -1
#> 
#> attr(,"used_priors")$prec_hyp_param
#> [1] 1e+00 1e-05 1e+00 1e-03 1e+00
#> 
#> attr(,"used_priors")$omega_param
#> [1]  1 50  1 10  1
#> 
#> attr(,"used_priors")$wishdf_param
#> [1] 20
#> 
#> attr(,"used_priors")$prec_logy_hyp_param
#> [1] 4 1
#> 
```
