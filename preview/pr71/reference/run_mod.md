# Run Jags Model

run_mod() takes a data frame and adjustable mcmc inputs to
[`runjags::run.jags()`](https://rdrr.io/pkg/runjags/man/run.jags.html)
as an mcmc bayesian model to estimate antibody dynamic curve parameters.
The
[`rjags::jags.model()`](https://rdrr.io/pkg/rjags/man/jags.model.html)
models seroresponse dynamics to an infection. The antibody dynamic curve
includes the following parameters:

- y0 = baseline antibody concentration

- y1 = peak antibody concentration

- t1 = time to peak

- r = shape parameter

- alpha = decay rate

## Usage

``` r
run_mod(
  data,
  file_mod,
  nchain = 4,
  nadapt = 0,
  nburn = 0,
  nmc = 100,
  niter = 100,
  strat = NA,
  with_post = FALSE,
  include_subs = FALSE
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
  specifies the number of mcmc chains to be run per jags model.

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

- include_subs:

  A [logical](https://rdrr.io/r/base/logical.html) value specifying
  whether posterior distributions should be included for all subjects. A
  value of [FALSE](https://rdrr.io/r/base/logical.html) will only
  include the predictive distribution.

## Value

A [list](https://rdrr.io/r/base/list.html) containing the following
elements:

- `"jags.post"`: a [list](https://rdrr.io/r/base/list.html) containing
  one or more
  [runjags::runjags](https://rdrr.io/pkg/runjags/man/runjags-class.html)
  objects (one per stratum).

- A [`base::data.frame()`](https://rdrr.io/r/base/data.frame.html)
  titled `curve_params` that contains the posterior distribution will be
  exported with the following attributes:

  - `iteration` = number of sampling iterations

  - `chain` = number of mcmc chains run; between 1 and 4

  - `indexid` = "newperson", indicating posterior distribution

  - `antigen_iso` = antibody/antigen type combination being evaluated

  - `alpha` = posterior estimate of decay rate

  - `r` = posterior estimate of shape parameter

  - `t1` = posterior estimate of time to peak

  - `y0` = posterior estimate of baseline antibody concentration

  - `y1` = posterior estimate of peak antibody concentration

  - `stratified variable` = the variable used to stratify jags model

- A [list](https://rdrr.io/r/base/list.html) of `attributes` that
  summarize the jags inputs, including:

  - `class`: Class of the output object.

  - `nChain`: Number of chains run.

  - `nParameters`: The amount of parameters estimated in the model.

  - `nIterations`: Number of iteration specified.

  - `nBurnin`: Number of burn ins.

  - `nThin`: Thinning number (niter/nmc).

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
#> Welcome to JAGS 4.3.2 on Tue Apr 29 20:16:56 2025
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
#> All chains have finished
#> Warning: The adaptation phase of one or more models was not completed in 100 iterations, so the current samples may not be optimal - try increasing the number of iterations to the "adapt" argument
#> Simulation complete.  Reading coda files...
#> Coda files loaded successfully
#> Finished running the simulation
#> Calling 4 simulations using the parallel method...
#> Following the progress of chain 1 (the program will wait for all chains
#> to finish before continuing):
#> Welcome to JAGS 4.3.2 on Tue Apr 29 20:17:46 2025
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
