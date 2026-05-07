
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `{serodynamics}`

<!-- badges: start -->

[![](https://codecov.io/gh/ucdavis/serodynamics/branch/main/graph/badge.svg)](https://app.codecov.io/gh/ucdavis/serodynamics)
[![CodeFactor](https://www.codefactor.io/repository/github/ucdavis/serodynamics/badge)](https://www.codefactor.io/repository/github/ucdavis/serodynamics)
[![R build
status](https://github.com/ucdavis/serodynamics/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ucdavis/serodynamics/actions)
[![](https://www.r-pkg.org/badges/version/serodynamics?color=orange)](https://cran.r-project.org/package=serodynamics)
[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

<!-- badges: end -->

The goal of `{serodynamics}` is to implement methods for modeling
longitudinal antibody responses to infection.

The package provides Bayesian MCMC modeling capabilities using either:

- **JAGS** (Just Another Gibbs Sampler) via `runjags` - the original
  implementation
- **Stan** via `cmdstanr` - a modern, efficient alternative (optional)

Both interfaces use the same data preparation and analysis workflow,
allowing users to choose their preferred Bayesian modeling framework.

## Installation

You can install the development version of `{serodynamics}` from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("UCD-SERG/serodynamics")
```

### Stan Support (Optional)

To use Stan models (via `run_mod_stan()`), you’ll also need to install
`cmdstanr`:

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
