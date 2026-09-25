# Create Prior Predictive Plot

Creates a prior predictive plot. The prior predictive plot can represent
either the population or predictive level parameters. Output figures
consist of either a density plot of the parameters or the varying
plotted trajectories. Prior draws are generated through the hierarchical
model:

\$\$ \mu\_{\mathrm{par}} \rightarrow \mathrm{prec}\_{\mathrm{par}}
\rightarrow \mathrm{par} \rightarrow (y_0, y_1, t_1, \alpha, r) \$\$

where the transformed parameters are

\$\$ y_0 = \exp(\mathrm{par}\_1) \$\$

\$\$ y_1 = y_0 + \exp(\mathrm{par}\_2) \$\$

\$\$ t_1 = \exp(\mathrm{par}\_3) \$\$

\$\$ \alpha = \exp(\mathrm{par}\_4) \$\$

\$\$ r = 1 + \exp(\mathrm{par}\_5). \$\$

## Usage

``` r
prior_predict(
  mu_hyp_param = NULL,
  prec_hyp_param = NULL,
  omega_param = NULL,
  wishdf_param = NULL,
  prec_logy_hyp_param = NULL,
  n = 1000,
  type = c("curves", "density"),
  time = seq(0, 200, length.out = 200),
  log_y = FALSE,
  seed = NULL
)
```

## Arguments

- mu_hyp_param:

  A [numeric](https://rdrr.io/r/base/numeric.html)
  [vector](https://rdrr.io/r/base/vector.html) of 5 values representing
  the prior mean for the population level parameters parameters (y0, y1,
  t1, alpha, r) for each biomarker. Will be 5 values long specified by
  the user, representing the following parameters:

  - y0 = baseline antibody concentration

  - y1 = peak antibody concentration

  - t1 = time to peak

  - alpha = decay rate

  - r = shape parameter

- prec_hyp_param:

  A [numeric](https://rdrr.io/r/base/numeric.html)
  [vector](https://rdrr.io/r/base/vector.html) of 5 values corresponding
  to hyperprior diagonal entries for the precision matrix (i.e. inverse
  variance) representing prior covariance of uncertainty around
  `mu_hyp_param`.

- omega_param:

  A [numeric](https://rdrr.io/r/base/numeric.html)
  [vector](https://rdrr.io/r/base/vector.html) of 5 values corresponding
  to the diagonal entries representing the Wishart hyperprior
  distributions of `prec_hyp_param`, describing how much we expect
  parameters to vary between individuals.

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

- n:

  Number of prior draws. Default is 1000.

- type:

  Character string specifying the output visualization. `"curves"` plots
  prior-predictive antibody trajectories and `"density"` plots marginal
  parameter densities.

- time:

  Numeric vector giving times at which prior-predictive antibody
  trajectories should be evaluated. Defaults to 200 equally spaced
  points between 0 and 200.

- log_y:

  Logical. If `TRUE`, prior predictive antibody curves are displayed on
  a log10 y-axis. Only applies when `type = "curves"`. Default is
  `FALSE`.

- seed:

  Optional integer seed for reproducible prior simulation.

## Value

An object of class `"serodynamics_prior_predict"` containing the plot
and simulated prior draws. The object prints as a ggplot. Quantiles
(2.5%, median, and 97.5%) for each biological model parameter are stored
in the `"prior_summary"` attribute and can be retrieved with
[`summary()`](https://rdrr.io/r/base/summary.html).

## Examples

``` r
if (FALSE) { # \dontrun{
pp <- prior_predict(
  mu_hyp_param = c(0.5, 5, 2, -2, -3),
  prec_hyp_param = rep(1, 5),
  omega_param = c(1, 5, 1, 5, 1),
  wishdf_param = 20,
  prec_logy_hyp_param = c(4, 1),
  n = 500,
  type = "curves"
)

pp
summary(pp)

prior_predict(
  mu_hyp_param = c(0.5, 5, 2, -2, -3),
  prec_hyp_param = rep(1, 5),
  omega_param = c(1, 5, 1, 5, 1),
  wishdf_param = 20,
  prec_logy_hyp_param = c(4, 1),
  n = 1000,
  type = "density"
)
} # }
```
