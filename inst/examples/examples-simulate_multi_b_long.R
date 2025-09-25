set.seed(924)

# Small demo setup
n_blocks  <- 2
time_grid <- c(0, 7, 14, 30)

# Build sigma_p (5x5) and sigma_b (B x B)
sd_p <- c(0.35, 0.45, 0.25, 0.30, 0.25)
R_p  <- matrix(0.25, 5, 5)
diag(R_p) <- 1
sigma_p <- diag(sd_p) %*% R_p %*% diag(sd_p)

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

# Peek at the long table
head(sim$data)

# Optional: quick check of one subject’s time series (interactive only)
if (interactive()) {
  d <- subset(sim$data, Subject == "1" & antigen_iso == "1")
  plot(d$time_days, d$value, type = "b",
       main = "Simulated biomarker 1 (Subject 1)",
       xlab = "Days", ylab = "Value")
}
