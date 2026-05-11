# Run Stan Model

`run_mod_stan()` takes a data frame and adjustable MCMC inputs to fit a
Bayesian model using Stan (via cmdstanr) to estimate antibody dynamic
curve parameters. The model estimates seroresponse dynamics to an
infection. The antibody dynamic curve includes the following parameters:

- y0 = baseline antibody concentration

- y1 = peak antibody concentration

- t1 = time to peak

- alpha = decay rate

- shape = shape parameter

## Usage

``` r
run_mod_stan(
  data,
  file_mod = serodynamics_example("model.stan"),
  nchain = 4,
  nadapt = 1000,
  niter = 1000,
  strat = NA,
  with_post = FALSE,
  ...
)
```

## Arguments

- data:

  A [`base::data.frame()`](https://rdrr.io/r/base/data.frame.html) with
  the required columns (see details).

- file_mod:

  The name of the file that contains model structure (a .stan file).

- nchain:

  An [integer](https://rdrr.io/r/base/integer.html) between 1 and 4 that
  specifies the number of MCMC chains to be run per Stan model.

- nadapt:

  An [integer](https://rdrr.io/r/base/integer.html) specifying the
  number of warmup/adaptation iterations per chain (Stan equivalent of
  JAGS adapt + burnin).

- niter:

  An [integer](https://rdrr.io/r/base/integer.html) specifying the
  number of post-warmup iterations.

- strat:

  A [character](https://rdrr.io/r/base/character.html) string specifying
  the stratification variable, entered in quotes.

- with_post:

  A [logical](https://rdrr.io/r/base/logical.html) value specifying
  whether a raw `stan_fit` component should be included as an element of
  the [list](https://rdrr.io/r/base/list.html) object returned by
  `run_mod_stan()` (see `Value` section below for details). Note: These
  objects can be large.

- ...:

  Arguments passed on to
  [`prep_priors_stan`](https:/ucd-serg.github.io/serodynamics/preview/pr175/reference/prep_priors_stan.md)

  `max_antigens`

  :   An [integer](https://rdrr.io/r/base/integer.html) specifying how
      many antigen-isotypes (biomarkers) will be modeled.

  `mu_hyp_param`

  :   A [numeric](https://rdrr.io/r/base/numeric.html)
      [vector](https://rdrr.io/r/base/vector.html) of 5 values
      representing the prior mean for the population level parameters
      parameters (y0, y1, t1, alpha, shape) for each biomarker. If
      specified, must be 5 values long, representing the following
      parameters:

      - y0 = baseline antibody concentration (default = 1.0)

      - y1 = peak antibody concentration (default = 7.0)

      - t1 = time to peak (default = 1.0)

      - alpha = decay rate (default = -4.0)

      - shape = shape parameter (default = -1.0)

  `prec_hyp_param`

  :   A [numeric](https://rdrr.io/r/base/numeric.html)
      [vector](https://rdrr.io/r/base/vector.html) of 5 values
      corresponding to hyperprior diagonal entries for the precision
      matrix (i.e. inverse variance) representing prior covariance of
      uncertainty around `mu_hyp_param`. If specified, must be 5 values
      long:

      - defaults: y0 = 1.0, y1 = 0.00001, t1 = 1.0, alpha = 0.001, shape
        = 1.0

  `omega_param`

  :   A [numeric](https://rdrr.io/r/base/numeric.html)
      [vector](https://rdrr.io/r/base/vector.html) of 5 values
      corresponding to the diagonal entries representing the Wishart
      hyperprior distributions of `prec_hyp_param`, describing how much
      we expect parameters to vary between individuals. If specified,
      must be 5 values long:

      - defaults: y0 = 1.0, y1 = 50.0, t1 = 1.0, alpha = 10.0, shape =
        1.0

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
[dplyr::tbl_df](https://dplyr.tidyverse.org/reference/defunct.html) that
contains MCMC samples from the joint posterior distribution of the model
parameters, conditional on the provided input `data`, including the same
structure as
[`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr175/reference/run_mod.md).

## Examples

``` r
# This example requires cmdstanr and CmdStan to be installed
# See ?run_mod_stan for installation instructions

if (requireNamespace("cmdstanr", quietly = TRUE)) {
  # Check if CmdStan is installed
  cmdstan_available <- tryCatch(
    {
      cmdstanr::cmdstan_version()
      TRUE
    },
    error = function(e) FALSE
  )
  
  if (cmdstan_available) {
    library(dplyr)
    set.seed(1)
    strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
      sim_case_data(n = 100) |>
      mutate(strat = "stratum 2")
    strat2 <- serocalculator::typhoid_curves_nostrat_100 |>
      sim_case_data(n = 100) |>
      mutate(strat = "stratum 1")
    
    dataset <- bind_rows(strat1, strat2)
    
    fitted_model <- run_mod_stan(
      data = dataset, # The data set input
      file_mod = serodynamics_example("model.stan"),
      nchain = 4, # Number of mcmc chains to run
      nadapt = 500, # Number of warmup iterations
      niter = 1000, # Number of sampling iterations
      strat = "strat" # Variable to be stratified
    )
  }
}
```
