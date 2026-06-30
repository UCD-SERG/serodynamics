# Priors for the Kronecker (multi-biomarker) model

`prep_priors_multi_b()` builds Wishart hyperparameters for the
within-biomarker precision matrix `T_P` and the across-biomarker
precision matrix `T_B` used in the Kronecker prior `T = T_B %x% T_P`.

## Usage

``` r
prep_priors_multi_b(
  n_blocks,
  omega_p_scale = rep(0.1, 5),
  nu_p = 6,
  omega_b_scale = rep(1, n_blocks),
  nu_b = n_blocks + 1
)
```

## Arguments

- n_blocks:

  Integer scalar (B): number of biomarkers.

- omega_p_scale:

  Numeric length-5 vector for the diagonal of Omega_P (parameter scale).

- nu_p:

  Numeric scalar: degrees of freedom for `T_P ~ Wishart(Omega_P, nu_p)`.

- omega_b_scale:

  Numeric length-`n_blocks` vector for the diagonal of Omega_B
  (biomarker scale).

- nu_b:

  Numeric scalar: degrees of freedom for `T_B ~ Wishart(Omega_B, nu_b)`.

## Value

A list with elements `OmegaP`, `nuP`, `OmegaB`, `nuB`.

## Author

Kwan Ho Lee

## Examples

``` r
# Basic usage: 3 biomarkers, weakly-informative defaults
pri <- prep_priors_multi_b(n_blocks = 3)
str(pri)
#> List of 4
#>  $ OmegaP: num [1:5, 1:5] 0.1 0 0 0 0 0 0.1 0 0 0 ...
#>  $ nuP   : num 6
#>  $ OmegaB: num [1:3, 1:3] 1 0 0 0 1 0 0 0 1
#>  $ nuB   : num 4

# Custom scales (and degrees of freedom)
pri_custom <- prep_priors_multi_b(
  n_blocks      = 4,
  omega_p_scale = c(0.2, 0.2, 0.3, 0.3, 0.4),
  nu_p          = 7,
  omega_b_scale = rep(1.5, 4),
  nu_b          = 6
)
str(pri_custom)
#> List of 4
#>  $ OmegaP: num [1:5, 1:5] 0.2 0 0 0 0 0 0.2 0 0 0 ...
#>  $ nuP   : num 7
#>  $ OmegaB: num [1:4, 1:4] 1.5 0 0 0 0 1.5 0 0 0 0 ...
#>  $ nuB   : num 6
```
