# Minimal end-to-end example (small settings for speed)

# 1) Write the Kronecker model once
model_path <- write_model_ch2_kron(file.path(tempdir(), "model_ch2_kron.jags"))

# 2) Simulate a tiny dataset
set.seed(926)
n_blocks  <- 2
time_grid <- c(0, 7, 14, 30)

sd_p <- c(0.35, 0.45, 0.25, 0.30, 0.25)
R_p  <- matrix(0.25, 5, 5)
diag(R_p) <- 1
sigma_p <- diag(sd_p) %*% R_p %*% diag(sd_p)

R_b <- matrix(c(1, 0.5,
                0.5, 1), n_blocks, n_blocks, byrow = TRUE)
sd_b <- rep(0.6, n_blocks)
sigma_b <- diag(sd_b) %*% R_b %*% diag(sd_b)

sim <- simulate_multi_b_long(
  n_id      = 5,
  n_blocks  = n_blocks,
  time_grid = time_grid,
  sigma_p   = sigma_p,
  sigma_b   = sigma_b
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
if (interactive()) {
  out <- run_mod_kron(
    data     = long_tbl,
    file_mod = model_path,
    nchain   = 2, nadapt = 200, nburn = 200,
    nmc      = 200, niter = 2000,
    strat    = NA
  )
}
