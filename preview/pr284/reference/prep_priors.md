# Prepare priors

Takes multiple [vector](https://rdrr.io/r/base/vector.html) inputs to
allow for modifiable priors. Priors must be specified as an option in
[`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr284/reference/run_serodynamics.md).

## Usage

``` r
prep_priors(
  max_antigens,
  mu_hyp_param = NULL,
  prec_hyp_param = NULL,
  omega_param = NULL,
  wishdf_param = NULL,
  prec_logy_hyp_param = NULL,
  decay_type = "power"
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
  t1, r, alpha) for each biomarker. Must be 5 values long, representing
  the following parameters:

  - y0 = baseline antibody concentration

  - y1 = peak antibody concentration

  - t1 = time to peak

  - r = shape parameter (If running `decay_type == "exponential"` no
    shape parameter needs to be specified).

  - alpha = decay rate When `decay_type = "exponential"` only 4
    parameters (y0, y1, t1, alpha) are used.

- prec_hyp_param:

  A [numeric](https://rdrr.io/r/base/numeric.html)
  [vector](https://rdrr.io/r/base/vector.html) of 5 values corresponding
  to hyperprior diagonal entries for the precision matrix (i.e. inverse
  variance) representing prior covariance of uncertainty around
  `mu_hyp_param`. Must be 5 values long corresponding to the 5 estimated
  parameters (4 values when `decay_type = "exponential"`).

- omega_param:

  A [numeric](https://rdrr.io/r/base/numeric.html)
  [vector](https://rdrr.io/r/base/vector.html) of 5 values corresponding
  to the diagonal entries representing the Wishart hyperprior
  distributions of `prec_hyp_param`, describing how much we expect
  parameters to vary between individuals (4 values when
  `decay_type = "exponential"`). Must be 5 values long corresponding to
  the 5 estimated parameters.

- wishdf_param:

  An [integer](https://rdrr.io/r/base/integer.html)
  [vector](https://rdrr.io/r/base/vector.html) of 1 value specifying the
  degrees of freedom for the Wishart hyperprior distribution of
  `prec_hyp_param`. Must be 1 value long.

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
  individual variation. Must be 2 values long.

- decay_type:

  A [character](https://rdrr.io/r/base/character.html) string specifying
  the decay function used in the model. Options are `"power"` and
  `"exponential"`. Default is `"power"`. The `"power"` option uses
  `y(t) = (y1^(1-shape) - (1-shape)*alpha*(t-t1))^(1/(1-shape))`. The
  `"exponential"` option uses `y(t) = y1 * exp(-alpha*(t-t1))`. The
  exponential model does not estimate `shape`; its processed output
  includes `shape = 1` as a fixed value to preserve the common output
  structure. Note: `prep_priors()` validates 5-element prior vector for
  power decay and 4-element prior vectors for exponential decay (the
  fifth (`shape`) prior is excluded in exponential decay).

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
```
