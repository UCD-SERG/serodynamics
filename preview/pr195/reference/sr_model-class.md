# `sr_model` class

An S3 class representing the output of a Bayesian MCMC model fitted by
[`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr195/reference/run_mod.md).
The `sr_model` object is a subclass of
[tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
containing MCMC samples from the joint posterior distribution of
host-specific antibody kinetic parameters, conditional on the provided
input data.

Each row represents one posterior draw for one parameter, one
antigen-isotype combination, one subject, and one stratification level.

## Data columns

- Iteration:

  [integer](https://rdrr.io/r/base/integer.html) MCMC sampling iteration
  index.

- Chain:

  [integer](https://rdrr.io/r/base/integer.html) MCMC chain index
  (between 1 and the number of chains specified in
  [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr195/reference/run_mod.md)).

- Parameter:

  [character](https://rdrr.io/r/base/character.html) name of the
  antibody dynamic curve parameter. One of:

  - `y0` – baseline antibody concentration

  - `y1` – peak antibody concentration

  - `t1` – time to peak

  - `shape` – shape parameter

  - `alpha` – decay rate

- Iso_type:

  [character](https://rdrr.io/r/base/character.html) antibody/antigen
  isotype combination being evaluated (e.g., `"HlyE_IgA"`,
  `"HlyE_IgG"`).

- Stratification:

  [character](https://rdrr.io/r/base/character.html) the level of the
  stratification variable used when fitting the model, or `"None"` if no
  stratification was specified.

- Subject:

  [character](https://rdrr.io/r/base/character.html) identifier of the
  subject. Includes observed subjects as well as `"newperson"`, which
  represents the posterior predictive distribution for a hypothetical
  new individual with no observed data.

- value:

  [numeric](https://rdrr.io/r/base/numeric.html) posterior sample value
  of the parameter.

## Attributes

In addition to the standard
[tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
attributes (`names`, `row.names`, `class`), an `sr_model` object carries
the following custom attributes:

- nChains:

  [integer](https://rdrr.io/r/base/integer.html) number of MCMC chains
  run.

- nParameters:

  [integer](https://rdrr.io/r/base/integer.html) number of parameters
  estimated in the model.

- nIterations:

  [integer](https://rdrr.io/r/base/integer.html) total number of MCMC
  iterations specified.

- nBurnin:

  [integer](https://rdrr.io/r/base/integer.html) number of burn-in
  iterations discarded before sampling.

- nThin:

  [integer](https://rdrr.io/r/base/integer.html) thinning interval
  (ratio of total iterations to retained samples, i.e., `niter / nmc`).

- population_params:

  (optional) a
  [tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
  of modeled population-level parameters, included when
  `with_pop_params = TRUE` in
  [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr195/reference/run_mod.md).
  Indexed by `Iteration`, `Chain`, `Parameter`, `Iso_type`, and
  `Stratification`. Contains the following population parameters:

  - `mu.par` – the population means of the host-specific model
    parameters (on logarithmic scales).

  - `prec.par` – the population precision matrix of the hyperparameters
    (with diagonal elements equal to inverse variances).

  - `prec.logy` – a vector of population precisions (inverse variances),
    one per antigen/isotype combination.

- priors:

  a [list](https://rdrr.io/r/base/list.html) summarizing the input
  priors used in the model, with the following elements:

  - `mu_hyp_param` – prior means for y0, y1, t1, shape, and alpha.

  - `prec_hyp_param` – precision hyperparameters (inverse variances).

  - `omega_param` – Wishart hyperprior diagonal entries.

  - `wishdf` – degrees of freedom for the Wishart distribution.

  - `prec_logy_hyp_param` – log-scale precision hyperparameters.

- fitted_residuals:

  a [data.frame](https://rdrr.io/r/base/data.frame.html) containing
  fitted values and residuals for all observations, with columns:

  - `Subject` – subject identifier.

  - `Iso_type` – antigen-isotype combination.

  - `t` – time since infection.

  - `fitted` – fitted value calculated from posterior parameter
    estimates.

  - `residual` – residual (observed minus fitted).

- jags.post:

  (optional) a [list](https://rdrr.io/r/base/list.html) of raw
  [`runjags::run.jags()`](https://rdrr.io/pkg/runjags/man/run.jags.html)
  output objects, one per stratification level. Included when
  `with_post = TRUE` in
  [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr195/reference/run_mod.md).
  These objects can be large.

## Construction

`sr_model` objects are created by
[`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr195/reference/run_mod.md)
and should not normally be constructed directly.

## Inheritance

The class hierarchy is `sr_model` \> `tbl_df` \> `tbl` \> `data.frame`,
so standard
[dplyr::dplyr-package](https://dplyr.tidyverse.org/reference/dplyr-package.html)
and
[tibble::tibble-package](https://tibble.tidyverse.org/reference/tibble-package.html)
operations work on `sr_model` objects.

## See also

- [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr195/reference/run_mod.md)
  – the constructor function.

- [`post_summ()`](https:/ucd-serg.github.io/serodynamics/preview/pr195/reference/post_summ.md)
  – posterior summary table.

- [`plot_predicted_curve()`](https:/ucd-serg.github.io/serodynamics/preview/pr195/reference/plot_predicted_curve.md)
  – predicted antibody response curves.

- [`plot_jags_trace()`](https:/ucd-serg.github.io/serodynamics/preview/pr195/reference/plot_jags_trace.md)
  – MCMC trace plots.

- [`plot_jags_dens()`](https:/ucd-serg.github.io/serodynamics/preview/pr195/reference/plot_jags_dens.md)
  – posterior density plots.

- [`plot_jags_Rhat()`](https:/ucd-serg.github.io/serodynamics/preview/pr195/reference/plot_jags_Rhat.md)
  – Rhat diagnostic plots.

- [`plot_jags_effect()`](https:/ucd-serg.github.io/serodynamics/preview/pr195/reference/plot_jags_effect.md)
  – effect size plots.
