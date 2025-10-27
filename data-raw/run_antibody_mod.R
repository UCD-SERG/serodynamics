# run_antibody_cmdstanr.R

library(cmdstanr)
library(dplyr)
library(tidyr)
library(purrr)
library(Matrix)

cmdstanr::set_cmdstan_path("~/cmdstan") # adjust if installed elsewhere

# === Load your dataset ===
longdata <- readRDS("~/Documents/GitHub/serodynamics/inst/extdata/longdata_typh.rds")

# Identify dimensions
# nsubj <- length(unique(dat$subj))
# n_antigen_isos <- length(unique(dat$iso))

# For each subject, count # of samples
# nsmpl <- dat %>%
#   group_by(subj) %>%
#   summarise(n = n()) %>%
#   pull(n)

max_nsmpl <- max(longdata$nsmpl)

# Create matrices (pad with NA)
# make_matrix <- function(var) {
#   dat %>%
#     group_by(subj) %>%
#     summarise(vals = list(!!sym(var))) %>%
#     pull(vals) %>%
#     map(~c(.x, rep(NA, max_nsmpl - length(.x)))) %>%
#     do.call(cbind, .)
# }
# 
# smpl_t_mat <- make_matrix("smpl_t")
# logy_mat <- make_matrix("logy")

# Binary masks (1 = missing, 0 = observed)

smpl_t_miss_mask <- ifelse(is.na(long$smpl.t), 1, 0)

## This is already an array
logy_miss_mask <- ifelse(is.na(long$logy), 1, 0)

# Replace NA with 0 for data placeholders (Stan ignores them when mask==1)
smpl_t_obs <- ifelse(is.na(longdata$smpl.t), 0, longdata$smpl.t)
logy_obs <- ifelse(is.na(longdata$logy), 0, longdata$logy)

# Number of params
n_params <- 5

priorspec <- prep_priors(max_antigens = longdata$n_antigen_isos)

# mu_hyp <- matrix(0, long$n_antigen_isos, n_params)
# prec_hyp <- array(diag(1/10, n_params), dim = c(long$n_antigen_isos, n_params, n_params))
# omega <- array(diag(1, n_params), dim = c(n_antigen_isos, n_params, n_params))
# wishdf <- rep(n_params + 2, n_antigen_isos)
# prec_logy_hyp <- cbind(rep(2, n_antigen_isos), rep(1, n_antigen_isos))

## Creating the stan data list 
stan_data <- list(
  nsubj = longdata$nsubj,
  n_antigen_isos = long$n_antigen_isos,
  n_params = n_params,
  max_nsmpl = max_nsmpl,
  nsmpl = longdata$nsmpl,
  smpl_t_obs = smpl_t_obs,
  logy_obs = logy_obs,
  smpl_t_miss_mask = smpl_t_miss_mask,
  logy_miss_mask = logy_miss_mask,
  mu_hyp = priorspec$mu.hyp,
  prec_hyp = priorspec$prec.hyp,
  omega = priorspec$omega,
  wishdf = priorspec$wishdf,
  prec_logy_hyp = priorspec$prec.logy.hyp
)

# Assuming model file is saved as "antibody_model.stan"
## Compiling the stan model
mod <- cmdstan_model("~/Documents/GitHub/serodynamics/inst/extdata/model.stan")

fit <- mod$sample(
  data = stan_data,
  seed = 42,
  chains = 2,
  parallel_chains = 2,
  iter_warmup = 200,
  iter_sampling = 200,
  adapt_delta = 0.9,
  max_treedepth = 12
)

