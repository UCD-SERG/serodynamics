# `dev/ch2` — Chapter 2 simulation study (`ch2sim`)

Author: Kwan Ho Lee

Research code for the correlated two-biomarker (IgG-IgA) extension of the
within-host antibody kinetics model, and its application to the Shigella SOSAR
cohort.

**This is not part of the serodynamics package.** It is excluded from the build
via `.Rbuildignore` and from linting via `.lintr.R`, and it depends on Stan
(`cmdstanr`), which serodynamics does not.

---

## How the code is loaded

Nothing here is `source()`d. The directory is itself a small package,
`ch2sim`, with a `DESCRIPTION` and an `R/`, so every script starts with two
`load_all()` calls:

```r
suppressMessages(devtools::load_all(PKG_DIR))   # serodynamics
suppressMessages(devtools::load_all(CH2_DIR))   # ch2sim, i.e. this directory
```

| provided by | functions |
|---|---|
| **serodynamics** (`R/`) | `make_corr_curve_params()`, `sim_case_data()`, `sim_obs_times()` |
| **ch2sim** (`dev/ch2/R/`) | `prep_ch2_standata()`, `run_mod_stan_ch2()`, `scenario_truth()`, `sim_ch2_clustered()` |

The Stan model is at `dev/ch2/inst/extdata/model_ch2.stan` and is reached with
`system.file("extdata", "model_ch2.stan", package = "ch2sim")`, so no script
depends on its relative path.

`harness_dryrun.R` is the one exception and says so in its header: it reads the
package sources directly because its purpose is to run where neither
serodynamics nor Stan is installed.

---

## What lives where

| path | contents | in the package build? |
|---|---|---|
| `R/` (repository root) | `make_corr_curve_params.R`, `sim_case_data.R`, `sim_obs_time.R` | yes |
| `dev/ch2/R/` | the Chapter 2 Stan functions | no |
| `dev/ch2/inst/extdata/` | `model_ch2.stan` | no |
| `dev/ch2/*.R`, `*.sh`, `*.tsv` | scripts, launchers, run manifests | no |

---

## Where to start

| If you want to know | Read |
|---|---|
| what the model is | `dev/ch2/inst/extdata/model_ch2.stan` |
| **where rho enters** | **`R/make_corr_curve_params.R`** — `cvec <- rho * sd_G * sd_A`, then `b_mat <- diag(cvec) %*% t(solve(chol_G))` |
| **that rho does not enter `sim_case_data()`** | `dev/ch2/ch2_run_one.R` — `sim_case_data()` receives only `curve_params`; the correlation is already inside it |
| how measurement error is added | **`R/sim_case_data.R`** — the `noise_sd` argument, multiplicative on the natural scale |
| how visit times are chosen | **`R/sim_obs_time.R`** — `spacing = "log"` |
| where the simulation truth comes from | `dev/ch2/rebuild_ch2_truth_targets.R` — the header records the source fit, its draws and its max R-hat |
| exactly what was run, with which settings | the `.tsv` manifests — one line per fitted cell |

---

## The model

Chapter 1 fits each antigen isotype with its own 5x5 covariance of subject-level
curve parameters. Chapter 2 adds a cross-biomarker block so a subject's IgG and
IgA parameters may covary. The block is diagonal — one correlation per curve
parameter — and the joint covariance is built as

```
L = [[L_G,  0    ],       B = diag(c) inv(L_G)'
     [B,    L_A|G]]       L_A|G = chol(Sigma_A - B B')
```

so the cross block is exactly `diag(c)`, both within-biomarker blocks are
unchanged, and `c = 0` recovers Chapter 1 exactly.

---

## Pipeline

```
dev/ch2/rebuild_ch2_truth_targets.R   fit to real data -> mu, Sigma, prec_logy
        |
R/make_corr_curve_params.R            joint draws with a known cross-correlation
        |
R/sim_case_data.R (noise_sd = ...)    visit schedule + curve + measurement error
        |
dev/ch2/R/stan_ch2_functions.R        fit model_ch2.stan (estimate_c = 0 or 1)
        |
dev/ch2/ch2_metrics.R                 bias, MSE, posterior variance, coverage
```

---

## Running it

```bash
cd dev/ch2
PKG_DIR=/path/to/serodynamics JOBS=jobs_rerun.tsv CORES_PER_JOB=8 \
  nohup ./run_jobs.sh > jobs.out 2>&1 &
```

`CH2_DIR` defaults to `.`, so running from this directory needs no extra
setting. Every cell writes `res_<TAG>.rds` independently and copies its CmdStan
CSVs into `csv_<TAG>/`, so a crash in one cell leaves the others untouched and a
completed fit survives a post-processing error.

```bash
Rscript ch2_metrics.R trial4 .      # combine archived and current results
```

---

## Files

### Functions (`R/`, loaded with `load_all()`)

| file | contents |
|---|---|
| `stan_ch2_functions.R` | `prep_ch2_standata()`, `run_mod_stan_ch2()` |
| `ch2_sim_functions.R` | `scenario_truth()`, `sim_ch2_clustered()`, `recovery_metrics()` |

### Scripts

| file | purpose |
|---|---|
| `ch2_run_one.R` | one simulation cell: one sample size, one seed, one arm |
| `ch2_run_shigella.R` | fits the model to the real Shigella cohort |
| `ch2_metrics.R` | pools converged seeds into bias, MSE, posterior variance and coverage, and writes the coverage figure. Takes one or more directories |
| `make_ch2_shigella_input.R` | carves one antigen's IgG/IgA pair out of the SOSAR cohort |
| `rebuild_ch2_truth_targets.R` | regenerates `ch2_truth_targets.rds` from recorded values, so the binary is not committed |
| `extract_fit_ch2_targets.R` | derives those values from a saved fit |
| `ch2_fit_to_curve_params.R` | fit -> `curve_params`, for simulating from a fitted population |
| `harness_dryrun.R` | runs the package sources with stubbed dependencies, no Stan needed |

### Launchers

`run_jobs.sh` is the general one and the only one needed for new work. The other
two predate it and are kept so earlier runs can be reproduced exactly.

| file | purpose |
|---|---|
| `run_jobs.sh` | concurrent runner driven by a manifest |
| `run_probe.sh` | short runs used to choose a sampler setting that converges |
| `run_production.sh` | the first multi-seed recovery run |

### Manifests — the record of what was actually run

Each line is one fitted cell: a name, a script, and every setting passed to it.
These are the reason a claim like "eight seeds were rerun at `adapt_delta =
0.999`" can be checked rather than taken on trust.

| file | what it ran |
|---|---|
| `jobs_rerun.tsv` | the eight cells that missed R-hat < 1.1, rerun at `adapt_delta = 0.999`, `max_treedepth = 13`, warmup 9000 |
| `jobs_shigella_v2.tsv` | Shigella: `c1_free` (16 chains, narrow init) and `shig_c0` (`estimate_c = 0`, the Chapter 1 arm needed for a LOO comparison) |
| `jobs_tail.tsv` | tests whether decay-shape is weakly identified because of the model or because of the follow-up schedule |

---

## Applying the model to Shigella

The cross-biomarker correlation is a within-person quantity, so both isotypes
have to come from the same subject set. Chapter 1 fitted each antigen-isotype
independently and could pick a different subset for each, which is not available
here. `make_ch2_shigella_input.R` therefore takes an explicit subset:

| subset | subjects | when to use |
|---|---|---|
| `overall` | 48 | ipaB, a virulence protein conserved across serotypes |
| `flexneri` | 25 | Sf2a, pooling Sf2a- and Sf3a-infected subjects (cross-reactivity) |
| `serotype` | 5-17 | the other O-antigens; too few subjects to identify a 10-dimensional covariance |

`prep_ch2_standata()` filters on `isos`, whose default is the typhoid antigen
names, so the Shigella isotype labels have to be supplied or relabelled. The
runner matches isotype suffixes rather than position — a positional map silently
swaps IgG and IgA, since the sorted labels put IgA first while the defaults put
IgG first.

---

## Things worth knowing before reading the diagnostics

* Measurement error enters on the **log** scale, matching `model.jags` L54 and
  `model_ch2.stan` L110. Simulating without it drives `prec_logy` towards the
  boundary and degrades the sampler geometry.
* The latent dimension is `nsubj x 10` (plus the non-centred `z`), so the
  posterior grows linearly in the number of simulated subjects. This, not
  `max_treedepth`, is what limits the feasible sample size.
* `cross_corr[3]` (time-to-peak) sits closest to the boundary and is the last to
  converge; `cross_corr[5]` (decay shape) converges easily but its interval spans
  zero. The two failures are at opposite ends and need different responses.
* The log-spaced schedule takes the first `n_obs` points of a fixed grid, so
  `n_obs` sets the observation **window**, not just its density. Under the
  default uniform draw the median subject stops at day 30 of a 400-day grid.
  `MIN_N_OBS` in `ch2_run_one.R` controls this.

## Requirements

`cmdstanr` and a working CmdStan install, plus serodynamics. Set `PKG_DIR` to
the serodynamics root before running the shell scripts.
