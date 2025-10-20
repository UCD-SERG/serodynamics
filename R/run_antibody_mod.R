# run_antibody_cmdstanr.R

library(dplyr)
library(tidyr)
library(cmdstanr)
cmdstanr::set_cmdstan_path("~/cmdstan") # adjust if installed elsewhere

# === Load your dataset ===
long <- readRDS("/mnt/data/longdata_typh.rds")

# Ensure expected columns exist or rename them
# Example: subj, antigen, smpl_t, logy
if (!("samp" %in% names(long))) {
  long <- long %>%
    arrange(subj, antigen, smpl_t) %>%
    group_by(subj) %>%
    mutate(samp = row_number()) %>%
    ungroup()
}

# Create integer indices
long <- long %>%
  mutate(
    subj_idx = as.integer(factor(subj)),
    antigen_idx = as.integer(factor(antigen))
  )

nsubj <- length(unique(long$subj_idx))
n_antigen_isos <- length(unique(long$antigen_idx))
max_nsmpl <- max(long$samp)
n_params <- 5

# --- observed/missing times
time_obs_df <- long %>% filter(!is.na(smpl_t)) %>%
  select(subj_idx, samp, smpl_t)
time_mis_df <- long %>% filter(is.na(smpl_t)) %>%
  select(subj_idx, samp)

# --- observed/missing logy
logy_obs_df <- long %>% filter(!is.na(logy)) %>%
  select(subj_idx, samp, antigen_idx, logy)
logy_mis_df <- long %>% filter(is.na(logy)) %>%
  select(subj_idx, samp, antigen_idx)

# --- build stan data
stan_data <- list(
  nsubj = nsubj,
  n_antigen_isos = n_antigen_isos,
  n_params = n_params,
  max_nsmpl = max_nsmpl,
  nsmpl = as.integer(long %>% group_by(subj_idx) %>% summarise(n = max(samp)) %>% pull(n)),
  N_obs_time = nrow(time_obs_df),
  time_subj = as.integer(time_obs_df$subj_idx),
  time_samp = as.integer(time_obs_df$samp),
  smpl_t_obs = as.numeric(time_obs_df$smpl_t),
  N_mis_time = nrow(time_mis_df),
  mis_time_subj = as.integer(time_mis_df$subj_idx),
  mis_time_samp = as.integer(time_mis_df$samp),
  N_obs_logy = nrow(logy_obs_df),
  logy_subj = as.integer(logy_obs_df$subj_idx),
  logy_samp = as.integer(logy_obs_df$samp),
  logy_antigen = as.integer(logy_obs_df$antigen_idx),
  logy_obs = as.numeric(logy_obs_df$logy),
  N_mis_logy = nrow(logy_mis_df),
  mislogy_subj = as.integer(logy_mis_df$subj_idx),
  mislogy_samp = as.integer(logy_mis_df$samp),
  mislogy_antigen = as.integer(logy_mis_df$antigen_idx),
  mu_hyp = matrix(0, nrow = n_params, ncol = n_antigen_isos),
  par_scale_prior = rep(2.5, n_antigen_isos),
  prec_logy_hyp = matrix(rep(c(1.0, 0.1), n_antigen_isos), nrow = 2)
)

# === compile Stan model ===
mod <- cmdstan_model("antibody_model_missing.stan")

# === sample ===
fit <- mod$sample(
  data = stan_data,
  seed = 2025,
  chains = 4,
  parallel_chains = 4,
  iter_warmup = 1000,
  iter_sampling = 1000,
  adapt_delta = 0.95,
  max_treedepth = 12
)

fit$save_output_files(dir = "stan_output")

# === check convergence ===
fit$summary(c("prec_logy", "sigma_par")) %>% print(n = 20)

# === extract imputations ===
draws <- fit$draws()
logy_imp <- as_draws_df(draws)[, grep("^logy_imputed", names(as_draws_df(draws)))]
cat("Mean imputed logy across draws:\n")
print(colMeans(logy_imp, na.rm = TRUE))

# === posterior predictive check example ===
pp_check <- fit$draws("logy_rep_obs") |> posterior::summarise_draws()
print(head(pp_check))
