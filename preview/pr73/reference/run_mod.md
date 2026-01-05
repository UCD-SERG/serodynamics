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
  [`prep_priors`](https://ucd-serg.github.io/serodynamics/preview/pr73/reference/prep_priors.md)

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
[dplyr::tbl_df](https://dplyr.tidyverse.org/reference/tbl_df.html) that
contains MCMC samples from the joint posterior distribution of the model
parameters, conditional on the provided input `data`, including the
following:

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
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union
#> Calling 4 simulations using the parallel method...
#> Following the progress of chain 1 (the program will wait for all chains
#> to finish before continuing):
#> Welcome to JAGS 4.3.2 on Mon Jan  5 22:39:50 2026
#> JAGS is free software and comes with ABSOLUTELY NO WARRANTY
#> Loading module: basemod: ok
#> Loading module: bugs: ok
#> . . Reading data file data.txt
#> . Compiling model graph
#>    Resolving undeclared variables
#>    Allocating nodes
#> Graph information:
#>    Observed stochastic nodes: 3020
#>    Unobserved stochastic nodes: 535
#>    Total graph size: 44517
#> . Reading parameter file inits1.txt
#> . Initializing model
#> . Adapting 100
#> -------------------------------------------------| 100
#> ++++++++++++++++++++++++++++++++++++++++++++++++++ 100%
#> Adaptation incomplete.
#> . Updating 100
#> -------------------------------------------------| 100
#> ************************************************** 100%
#> . . . . . . Updating 2000
#> -------------------------------------------------| 2000
#> ************************************************** 100%
#> . . . . Updating 0
#> . Deleting model
#> . 
#> All chains have finished
#> Warning: The adaptation phase of one or more models was not completed in 100 iterations, so the current samples may not be optimal - try increasing the number of iterations to the "adapt" argument
#> Simulation complete.  Reading coda files...
#> Coda files loaded successfully
#> Finished running the simulation
#> Calling 4 simulations using the parallel method...
#> Following the progress of chain 1 (the program will wait for all chains
#> to finish before continuing):
#> Welcome to JAGS 4.3.2 on Mon Jan  5 22:40:39 2026
#> JAGS is free software and comes with ABSOLUTELY NO WARRANTY
#> Loading module: basemod: ok
#> Loading module: bugs: ok
#> . . Reading data file data.txt
#> . Compiling model graph
#>    Resolving undeclared variables
#>    Allocating nodes
#> Graph information:
#>    Observed stochastic nodes: 2555
#>    Unobserved stochastic nodes: 535
#>    Total graph size: 39309
#> . Reading parameter file inits1.txt
#> . Initializing model
#> . Adapting 100
#> -------------------------------------------------| 100
#> ++++++++++++++++++++++++++++++++++++++++++++++++++ 100%
#> Adaptation incomplete.
#> . Updating 100
#> -------------------------------------------------| 100
#> ************************************************** 100%
#> . . . . . . Updating 2000
#> -------------------------------------------------| 2000
#> ************************************************** 100%
#> . . . . Updating 0
#> . Deleting model
#> . 
#> All chains have finished
#> Warning: The adaptation phase of one or more models was not completed in 100 iterations, so the current samples may not be optimal - try increasing the number of iterations to the "adapt" argument
#> Simulation complete.  Reading coda files...
#> Coda files loaded successfully
#> Finished running the simulation
```
