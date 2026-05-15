# Run Jags Model

`run_mod()` takes a data frame and adjustable MCMC inputs to
[`runjags::run.jags()`](https://rdrr.io/pkg/runjags/man/run.jags.html)
as an MCMC Bayesian model to estimate antibody dynamic curve parameters.
The
[`rjags::jags.model()`](https://rdrr.io/pkg/rjags/man/jags.model.html)
models seroresponse dynamics to an infection. The antibody dynamic curve
includes the following parameters:

- y0 = baseline antibody concentration

- y1 = peak antibody concentration

- t1 = time to peak

- shape = shape parameter

- alpha = decay rate

## Usage

``` r
run_mod(
  data,
  file_mod = serodynamics_example("model.jags"),
  nchain = 4,
  nadapt = 0,
  nburn = 0,
  nmc = 100,
  niter = 100,
  strat = NA,
  with_post = FALSE,
  ...
)
```

## Arguments

- data:

  A [`base::data.frame()`](https://rdrr.io/r/base/data.frame.html) with
  the following columns.

- file_mod:

  The name of the file that contains model structure.

- nchain:

  An [integer](https://rdrr.io/r/base/integer.html) between 1 and 4 that
  specifies the number of MCMC chains to be run per jags model.

- nadapt:

  An [integer](https://rdrr.io/r/base/integer.html) specifying the
  number of adaptations per chain.

- nburn:

  An [integer](https://rdrr.io/r/base/integer.html) specifying the
  number of burn ins before sampling.

- nmc:

  An [integer](https://rdrr.io/r/base/integer.html) specifying the
  number of samples in posterior chains.

- niter:

  An [integer](https://rdrr.io/r/base/integer.html) specifying the
  number of iterations.

- strat:

  A [character](https://rdrr.io/r/base/character.html) string specifying
  the stratification variable, entered in quotes.

- with_post:

  A [logical](https://rdrr.io/r/base/logical.html) value specifying
  whether a raw `jags.post` component should be included as an element
  of the [list](https://rdrr.io/r/base/list.html) object returned by
  `run_mod()` (see `Value` section below for details). Note: These
  objects can be large.

- ...:

  Arguments passed on to
  [`prep_priors`](https:/ucd-serg.github.io/serodynamics/preview/pr207/reference/prep_priors.md)

  `max_antigens`

  :   An [integer](https://rdrr.io/r/base/integer.html) specifying how
      many antigen-isotypes (biomarkers) will be modeled.

  `mu_hyp_param`

  :   A [numeric](https://rdrr.io/r/base/numeric.html)
      [vector](https://rdrr.io/r/base/vector.html) of 5 values
      representing the prior mean for the population level parameters
      parameters (y0, y1, t1, r, alpha) for each biomarker. If
      specified, must be 5 values long, representing the following
      parameters:

      - y0 = baseline antibody concentration (default = 1.0)

      - y1 = peak antibody concentration (default = 7.0)

      - t1 = time to peak (default = 1.0)

      - r = shape parameter (default = -4.0)

      - alpha = decay rate (default = -1.0)

  `prec_hyp_param`

  :   A [numeric](https://rdrr.io/r/base/numeric.html)
      [vector](https://rdrr.io/r/base/vector.html) of 5 values
      corresponding to hyperprior diagonal entries for the precision
      matrix (i.e. inverse variance) representing prior covariance of
      uncertainty around `mu_hyp_param`. If specified, must be 5 values
      long:

      - defaults: y0 = 1.0, y1 = 0.00001, t1 = 1.0, r = 0.001, alpha =
        1.0

  `omega_param`

  :   A [numeric](https://rdrr.io/r/base/numeric.html)
      [vector](https://rdrr.io/r/base/vector.html) of 5 values
      corresponding to the diagonal entries representing the Wishart
      hyperprior distributions of `prec_hyp_param`, describing how much
      we expect parameters to vary between individuals. If specified,
      must be 5 values long:

      - defaults: y0 = 1.0, y1 = 50.0, t1 = 1.0, r = 10.0, alpha = 1.0

  `wishdf_param`

  :   An [integer](https://rdrr.io/r/base/integer.html)
      [vector](https://rdrr.io/r/base/vector.html) of 1 value specifying
      the degrees of freedom for the Wishart hyperprior distribution of
      `prec_hyp_param`. If specified, must be 1 value long.

      - default = 20.0

      - The value of `wishdf_param` controls how informative the Wishart
        prior is. Higher values lead to tighter priors on individual
        variation. Lower values (e.g., 5–10) make the prior more weakly
        informative, which can help improve convergence if the model is
        over-regularized.

  `prec_logy_hyp_param`

  :   A [numeric](https://rdrr.io/r/base/numeric.html)
      [vector](https://rdrr.io/r/base/vector.html) of 2 values
      corresponding to hyperprior diagonal entries on the log-scale for
      the precision matrix (i.e. inverse variance) representing prior
      beliefs of individual variation. If specified, must be 2 values
      long:

      - defaults = 4.0, 1.0

## Value

An `sr_model` class object: a subclass of
[tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
that contains MCMC samples from the joint posterior distribution of the
model parameters, conditional on the provided input `data`, including
the following:

- `iteration` = Number of sampling iterations

- `chain` = Number of MCMC chains run; between 1 and 4

- `Parameter` = Parameter being estimated. Includes the following:

  - `y0` = Posterior estimate of baseline antibody concentration

  - `y1` = Posterior estimate of peak antibody concentration

  - `t1` = Posterior estimate of time to peak

  - `shape` = Posterior estimate of shape parameter

  - `alpha` = Posterior estimate of decay rate

- `Iso_type` = Antibody/antigen type combination being evaluated

- `Stratification` = The variable used to stratify jags model

- `Subject` = ID of subject being evaluated

- `value` = Estimated value of the parameter

- The following [attributes](https://rdrr.io/r/base/attributes.html) are
  included in the output:

  - `class`: Class of the output object.

  - `nChain`: Number of chains run.

  - `nParameters`: The amount of parameters estimated in the model.

  - `nIterations`: Number of iteration specified.

  - `nBurnin`: Number of burn ins.

  - `nThin`: Thinning number (niter/nmc).

  - `priors`: A [list](https://rdrr.io/r/base/list.html) that summarizes
    the input priors, including:

    - `mu_hyp_param`

    - `prec_hyp_param`

    - `omega_param`

    - `wishdf`

    - `prec_logy_hyp_param`

  - `fitted_residuals`: A
    [data.frame](https://rdrr.io/r/base/data.frame.html) containing
    fitted and residual values for all observations.

  - An optional `"jags.post"` attribute, included when argument
    `with_post` = TRUE.

## Author

Sam Schildhauer

## Examples

``` r
data(nepal_sees_jags_output, package = "serodynamics")
post_summ(nepal_sees_jags_output)
#> # A tibble: 20 × 11
#>    Iso_type Parameter Stratification       Mean       SD  Median  `2.5%` `25.0%`
#>    <chr>    <chr>     <chr>               <dbl>    <dbl>   <dbl>   <dbl>   <dbl>
#>  1 HlyE_IgA alpha     paratyphi         0.00266  3.92e-3 1.56e-3 1.99e-4 7.47e-4
#>  2 HlyE_IgA alpha     typhi             0.00293  4.18e-3 1.51e-3 1.48e-4 6.88e-4
#>  3 HlyE_IgA shape     paratyphi         1.63     2.82e-1 1.56e+0 1.27e+0 1.44e+0
#>  4 HlyE_IgA shape     typhi             1.77     4.41e-1 1.67e+0 1.26e+0 1.49e+0
#>  5 HlyE_IgA t1        paratyphi         4.28     2.11e+0 3.90e+0 1.56e+0 2.73e+0
#>  6 HlyE_IgA t1        typhi             7.91     5.98e+0 6.36e+0 1.95e+0 4.39e+0
#>  7 HlyE_IgA y0        paratyphi         3.83     2.65e+0 2.85e+0 1.07e+0 1.88e+0
#>  8 HlyE_IgA y0        typhi             2.90     2.23e+0 2.34e+0 7.70e-1 1.69e+0
#>  9 HlyE_IgA y1        paratyphi      2781.       4.19e+4 1.92e+2 7.45e+0 5.61e+1
#> 10 HlyE_IgA y1        typhi          1275.       6.42e+3 2.58e+2 9.11e+0 8.44e+1
#> 11 HlyE_IgG alpha     paratyphi         0.00202  2.11e-3 1.43e-3 2.25e-4 7.07e-4
#> 12 HlyE_IgG alpha     typhi             0.00196  1.88e-3 1.39e-3 2.69e-4 7.57e-4
#> 13 HlyE_IgG shape     paratyphi         1.41     1.56e-1 1.39e+0 1.17e+0 1.29e+0
#> 14 HlyE_IgG shape     typhi             1.49     3.78e-1 1.39e+0 1.08e+0 1.23e+0
#> 15 HlyE_IgG t1        paratyphi         5.02     1.87e+0 4.73e+0 2.18e+0 3.75e+0
#> 16 HlyE_IgG t1        typhi             7.67     6.84e+0 6.02e+0 1.59e+0 3.82e+0
#> 17 HlyE_IgG y0        paratyphi         2.46     9.14e-1 2.33e+0 1.23e+0 1.87e+0
#> 18 HlyE_IgG y0        typhi             2.11     1.40e+0 1.79e+0 4.79e-1 1.22e+0
#> 19 HlyE_IgG y1        paratyphi       929.       4.52e+3 2.73e+2 2.09e+1 1.08e+2
#> 20 HlyE_IgG y1        typhi           512.       9.65e+2 2.44e+2 2.77e+1 1.11e+2
#> # ℹ 3 more variables: `50.0%` <dbl>, `75.0%` <dbl>, `97.5%` <dbl>

if (FALSE) { # \dontrun{
if (!is.element(runjags::findjags(), c("", NULL))) {
  library(runjags)
  set.seed(1)
  library(dplyr)
  strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 100) |>
    mutate(strat = "stratum 2")
  strat2 <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 100) |>
    mutate(strat = "stratum 1")

  dataset <- bind_rows(strat1, strat2)

  fitted_model <- run_mod(
    data = dataset, # The data set input
    file_mod = serodynamics_example("model.jags"),
    nchain = 4, # Number of mcmc chains to run
    nadapt = 100, # Number of adaptations to run
    nburn = 100, # Number of unrecorded samples before sampling begins
    nmc = 1000,
    niter = 2000, # Number of iterations
    strat = "strat"
  ) # Variable to be stratified
}
} # }
```
