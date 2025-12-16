# Chapter 2 — Fake Data First, Then Fit

## 1 Current Model (what we already fit)

- Chapter 1 model fits subject-level parameters for each biomarker
  $\left( y_{0},t_{1},y_{1},\alpha,\rho \right)$.
- Within each biomarker: variation is captured by a covariance
  $\left( \Sigma_{P} \right)$.
- Across biomarkers: independence (block-diagonal),
  i.e. $${Cov}\!({vec}\left( \Theta_{i} \right)) = \Sigma_{P} \otimes I_{B}$$

## 2 Step A — Set up

Show R Code

``` r
set.seed(123)
library(tidyverse)
library(mvtnorm)   # rmvnorm
library(Matrix)    # kronecker
library(serodynamics)
```

## 3 Step B — Minimal helpers

## 4 Step C — Choose a “truth” and simulate fake data

Show R Code

``` r
# Choose B biomarkers and visit schedule
n_blocks  <- 2
time_grid <- c(0, 7, 14, 30)

# True ΣP (5×5): mild positive correlation among the five latent parameters
sd_p <- c(0.35, 0.45, 0.25, 0.30, 0.25)
R_p  <- matrix(0.25, 5, 5)
diag(R_p) <- 1
sigma_p <- diag(sd_p) %*% R_p %*% diag(sd_p)

# True ΣB (B×B): cross-biomarker correlation
R_b <- matrix(c(1, 0.5,
                0.5, 1), n_blocks, n_blocks, byrow = TRUE)
sd_b <- rep(0.6, n_blocks)
sigma_b <- diag(sd_b) %*% R_b %*% diag(sd_b)


# Run simulator
sim <- simulate_multi_b_long(
  n_id      = 5,
  n_blocks  = n_blocks,
  time_grid = time_grid,
  sigma_p   = sigma_p,
  sigma_b   = sigma_b
)

# This long table already matches prep_data() expectations:

sim$data |> dplyr::slice_head(n = 8)
```

## 5 Step D — Fit the independence model

Show R Code

``` r
# If our package is loaded, this is all we need:

sim_tbl <- serodynamics::as_case_data(
  sim$data,
  id_var        = "Subject",
  biomarker_var = "antigen_iso",
  value_var     = "value",
  time_in_days  = "time_days"
)

prepped <- prep_data(sim_tbl)
priors  <- prep_priors(max_antigens = prepped$n_antigen_isos)
fit_v0  <- run_mod(
 data     = sim_tbl,
 file_mod = serodynamics_example("model.jags"),  # our current model
 nchain = 4, nadapt = 1000, nburn = 500, nmc = 500, niter = 5000,
 strat = NA, with_post = TRUE
 )

fit_v0
```

## 6 Step E — Prepare for Correlated Model

- In Step D we fit the “independence” model: each biomarker had its own
  covariance for the 5 parameters, but biomarkers were assumed
  independent.
- Now we allow correlations **across biomarkers** as well as **within
  biomarkers**.
- Mathematically, we replace the block-diagonal assumption with a
  **Kronecker structure**:

$${Cov}\!({vec}\left( \Theta_{i} \right)) = \Sigma_{P} \otimes \Sigma_{B}$$

- Here:
  - $\Sigma_{P}$ = covariance of the 5 parameters
    $\left( y_{0},y_{1},t_{1},\alpha,\rho \right)$ within a biomarker.
  - $\Sigma_{B}$ = covariance across biomarkers.
  - The Kronecker product $\otimes$ builds a $5B \times 5B$ covariance.
- Implementation plan:
  1.  Define priors for $\Sigma_{P}$ and $\Sigma_{B}$ separately (via
      Wishart distributions).
  2.  Build the Kronecker precision matrix
      $\text{T} = \text{T}_{B} \otimes \text{T}_{P}$ inside JAGS.
  3.  Draw each subject’s stacked parameter vector from this
      multivariate prior.
  4.  Likelihood for observed antibody data is unchanged — only the
      prior covariance differs.

------------------------------------------------------------------------

### 6.1 E.1 Priors for the Correlated Model

We define a helper function `prep_priors_multiB()` that sets priors for
both $\Sigma_{P}$ (within-biomarker) and $\Sigma_{B}$
(across-biomarkers).

- $\text{T}_{P} \sim \text{Wishart}\left( \Omega_{P},\nu_{P} \right)$  
- $\text{T}_{B} \sim \text{Wishart}\left( \Omega_{B},\nu_{B} \right)$  
- Kronecker precision: $\text{T} = \text{T}_{B} \otimes \text{T}_{P}$

### 6.2 E.2 Write the new JAGS model file (Kronecker precision)

This is our `model.jags` with only one conceptual change:  
instead of independent

$$par\left\lbrack \text{subj},\text{b}, \right\rbrack \sim \mathcal{N}\left( \mu.par\left\lbrack \text{b}, \right\rbrack,\ \text{prec.par}\left\lbrack \text{b},, \right\rbrack \right)$$
where b is `cur_antigen_iso`

we draw **all biomarkers at once** for a subject with a **Kronecker
precision**:

$${vec}\left( par_{\text{subj},\cdot,\cdot} \right) \sim \mathcal{N}\!({vec}\left( \mu_{par} \right),\ \text{T}_{B} \otimes \text{T}_{P}).$$

- Everything else (transforms, likelihood, measurement precisions) stays
  as before.  
- We keep our hyperpriors for `mu.par` (the per-biomarker means), so it
  plugs right into our current
  [`prep_priors()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/prep_priors.md).

This is our new `model.jags` rename as `model_ch2_kron.jags`

#### 6.2.1 What changed vs. our current `model.jags`

- Removed the per-biomarker `prec.par[cur_antigen_iso,,] ~ dwish(...)`
  and
  `par[subj,cur_antigen_iso,] ~ dmnorm(mu.par[cur_antigen_iso,], prec.par[cur_antigen_iso,,])`.

- Replaced with one prior per subject on the stacked vector using
  $\text{T} = \text{T}_{B} \otimes \text{T}_{P}$

- Kept our `mu.par` prior and the likelihood exactly as is.

### 6.3 E.3: Minimal wrapper so we can keep calling one function

## 7 What are `OmegaP`, `nuP`, `OmegaB`, `nuB` — and why these defaults?

These are the **Wishart hyperparameters** for the **precision matrices**
(inverse covariances) used in the Kronecker prior:

- $\text{T}_{P} \sim \text{Wishart}\left( \Omega_{P},\nu_{P} \right)$ –
  within-biomarker parameter precision (5×5).
- $\text{T}_{B} \sim \text{Wishart}\left( \Omega_{B},\nu_{B} \right)$ –
  across-biomarker precision (B×B).

Generally speaking (JAGS Wishart):
$\mathbb{E}\left\lbrack \text{T} \right\rbrack \approx \nu \cdot \Omega^{-1}$
when $\nu$ is not tiny. So smaller diagonal entries in $\Omega$ imply
larger expected precision (i.e., smaller covariance), and vice versa.

### 7.1 Chosen weakly-informative defaults

``` r
OmegaP_scale = rep(0.1, 5);  nuP = 6
OmegaB_scale = rep(1.0, B);  nuB = B + 1
```

- `nuP = 6` is just above the dimension (5): proper but not tight.

- `OmegaP = 0.1 * I_5` is diffuse. With small `nuP`, the prior is wide;
  data will dominate.

- `nuB = B + 1` is a minimally-informative choice for a B×B Wishart.

- `OmegaB = I_B` centers `TauB` near identity while letting the data
  learn cross-biomarker correlation.

These are starting values. Validate with prior predictive checks
(simulate parameters → curves → sanity check ranges).

## 8 Putting it together

- **Independence model (our baseline)**: no changes.

- **Correlated model**: we supply both the usual priors and the new
  Kronecker priors:

Run Kronecker model (disabled for now)

``` r
# Step 1: simulate fake data (or load real Shigella data)
sim_tbl 

# Step 2: write the new Kronecker model file (once per session/project)
write_model_ch2_kron()

# Step 3: run the unified runner in correlated (Chapter 2) mode
fit_kron <- run_mod(
  data     = sim_tbl,
  file_mod = serodynamics_example("model.jags"),  # baseline model path (unused here)
  file_mod_kron = "model_ch2_kron.jags",          # use the Kronecker model
  correlated = TRUE,                              # <-- key switch
  nchain   = 4, nadapt = 1000, nburn = 500,
  nmc      = 500,  niter = 5000,
  strat    = NA,
  mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0)     # optional override
)

# Step 4: inspect results (same as with run_mod before)
fit_kron
```
