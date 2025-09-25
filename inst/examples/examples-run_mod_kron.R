# Minimal end-to-end example (small settings for speed)

# 1) Write the Kronecker model once
model_path <- write_model_ch2_kron(file.path(tempdir(), "model_ch2_kron.jags"))

# 2) Simulate a tiny dataset
set.seed(926)
B <- 2
time_grid <- c(0, 7, 14, 30)

sd_P <- c(0.35, 0.45, 0.25, 0.30, 0.25)
R_P  <- matrix(0.25, 5, 5)
diag(R_P) <- 1
sigma_p <- diag(sd_P) %*% R_P %*% diag(sd_P)

R_B <- matrix(c(1, 0.5,
                0.5, 1), B, B, byrow = TRUE)
sd_B <- rep(0.6, B)
sigma_b <- diag(sd_B) %*% R_B %*% diag(sd_B)

sim <- simulate_multiB_long(
  n_id = 4, B = B, time_grid = time_grid,
  Sigma_P = Sigma_P, Sigma_B = Sigma_B
)

# 3) Convert to case_data expected by prep_data/run_mod
long_tbl <- serodynamics::as_case_data(
  sim$data,
  id_var        = "Subject",
  biomarker_var = "antigen_iso",
  value_var     = "value",
  time_in_days  = "time_days"
)

# 4) Fit the Kronecker model (very small MCMC for demonstration)
out <- run_mod_kron(
  data     = long_tbl,
  file_mod = model_path,
  nchain   = 2, nadapt = 200, nburn = 200,
  nmc      = 200, niter = 2000,
  strat    = NA
)

print(dplyr::glimpse(out))
