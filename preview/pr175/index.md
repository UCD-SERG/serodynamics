# `{serodynamics}`

The goal of [serodynamics](https://github.com/ucdavis/serodynamics) is
to implement methods for modeling longitudinal antibody responses to
infection.

The package provides Bayesian MCMC modeling capabilities using either:

- **JAGS** (Just Another Gibbs Sampler) via `runjags` - the original
  implementation
- **Stan** via `cmdstanr` - a modern, efficient alternative (optional)

Both interfaces use the same data preparation and analysis workflow,
allowing users to choose their preferred Bayesian modeling framework.

## Installation

You can install the development version of
[serodynamics](https://github.com/ucdavis/serodynamics) from
[GitHub](https://github.com/) with:

``` r

# install.packages("pak")
pak::pak("ucdavis/serodynamics")
```

### Stan Support (Optional)

To use Stan models (via
[`run_mod_stan()`](https://ucd-serg.github.io/serodynamics/preview/pr175/reference/run_mod_stan.md)),
you’ll also need to install `cmdstanr`:

``` r

# Install cmdstanr from r-universe
install.packages("cmdstanr", 
                 repos = c("https://stan-dev.r-universe.dev",
                          getOption("repos")))

# Then install CmdStan
cmdstanr::install_cmdstan()
```

See the [cmdstanr documentation](https://mc-stan.org/cmdstanr/) for more
details.
