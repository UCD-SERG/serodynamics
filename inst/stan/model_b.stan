// Model B: Multivariate observation model for antibody kinetics
//
// This Stan model implements the same two-phase antibody kinetics curve
// as model.jags but replaces K independent univariate normal likelihoods
// with a single K-variate normal likelihood per time point, capturing
// residual correlations across antigen-isotype pairs (Model B).
//
// References:
//   Teunis et al. (2016). Biomarker dynamics: estimating infection rates
//   from serological data. Statistics in Medicine, 35(22), 3956-3967.
//   Hay et al. (2024). Epidemics, 100806.

functions {
  // Two-phase antibody kinetics curve on the log scale.
  //
  // Parameters (on the natural scale):
  //   t     - time since infection
  //   t1    - time to peak (> 0)
  //   y0    - baseline concentration (> 0)
  //   y1    - peak concentration (> y0)
  //   alpha - decay rate (> 0)
  //   rho   - shape parameter (> 1)
  real two_phase_log_y(real t, real t1, real y0, real y1,
                       real alpha, real rho) {
    real beta = (log(y1) - log(y0)) / t1;
    if (t <= t1) {
      return log(y0) + beta * t;
    } else {
      // Decay phase: see Teunis et al. (2016) eq. 15
      real arg = pow(y1, 1.0 - rho) - (1.0 - rho) * alpha * (t - t1);
      return log(arg) / (1.0 - rho);
    }
  }
}

data {
  int<lower=1> N;                              // number of subjects
  int<lower=1> K;                              // number of antigen-isotype pairs
  int<lower=1> max_obs;                        // max observations per subject
  array[N] int<lower=1, upper=max_obs> n_obs;  // observations per subject
  array[N, max_obs] real time_obs;             // observation times (padded with 0)
  array[N, max_obs, K] real log_y_obs;         // log antibody levels (padded with 0)

  // Hyperprior values (correspond to JAGS defaults)
  // Means for the 5 log-scale parameters per biomarker:
  //   [log_y0, log_delta, log_t1, log_alpha, log_shape_minus_1]
  vector[5] mu_hyp;         // prior means for mu_par
  vector<lower=0>[5] sigma_hyp;  // prior SDs for mu_par
}

parameters {
  // Population-level means per biomarker (same for all K biomarkers)
  array[K] vector[5] mu_par;

  // Population-level standard deviations per biomarker per parameter
  array[K] vector<lower=0>[5] sigma_par;

  // Subject × biomarker raw (log-scale) parameters
  // par[i, k] = [log_y0, log_delta, log_t1, log_alpha, log_shape_minus_1]
  array[N, K] vector[5] par;

  // Residual covariance: Cholesky factor of correlation matrix (K × K)
  cholesky_factor_corr[K] L_Omega_eps;

  // Marginal standard deviations for residuals (one per biomarker)
  vector<lower=0>[K] tau_eps;
}

transformed parameters {
  // Cholesky factor of the residual covariance matrix
  matrix[K, K] L_Sigma_eps = diag_pre_multiply(tau_eps, L_Omega_eps);
}

model {
  // --- Priors on residual covariance structure ---
  // LKJ prior on correlation matrix (eta=2 slightly regularizes toward identity)
  L_Omega_eps ~ lkj_corr_cholesky(2.0);
  // Half-Cauchy prior on residual scales
  tau_eps ~ cauchy(0.0, 2.5);

  // --- Priors on population-level means ---
  for (k in 1:K) {
    mu_par[k] ~ normal(mu_hyp, sigma_hyp);
    sigma_par[k] ~ exponential(1.0);
  }

  // --- Hierarchical subject-level parameters and likelihood ---
  for (i in 1:N) {
    for (k in 1:K) {
      // Independent normal priors on each of the 5 log-scale parameters
      par[i, k] ~ normal(mu_par[k], sigma_par[k]);
    }

    for (o in 1:n_obs[i]) {
      real t = time_obs[i, o];
      vector[K] mu_it;

      for (k in 1:K) {
        // Transform log-scale parameters to natural scale
        real y0    = exp(par[i, k][1]);
        real y1    = y0 + exp(par[i, k][2]);  // peak = baseline + positive delta
        real t1    = exp(par[i, k][3]);
        real alpha = exp(par[i, k][4]);
        real rho   = exp(par[i, k][5]) + 1.0; // shape > 1

        mu_it[k] = two_phase_log_y(t, t1, y0, y1, alpha, rho);
      }

      // K-variate normal likelihood (Model B: correlated residuals)
      to_vector(log_y_obs[i, o]) ~ multi_normal_cholesky(mu_it, L_Sigma_eps);
    }
  }
}

generated quantities {
  // Recover the full correlation and covariance matrices for diagnostics
  matrix[K, K] Omega_eps = multiply_lower_tri_self_transpose(L_Omega_eps);
  matrix[K, K] Sigma_eps = quad_form_diag(Omega_eps, tau_eps);

  // Natural-scale parameter summaries for each subject × biomarker
  // Used by postprocess_stan_output() to build the sr_model tibble
  array[N, K] real y0_nat;
  array[N, K] real y1_nat;
  array[N, K] real t1_nat;
  array[N, K] real alpha_nat;
  array[N, K] real shape_nat;

  for (i in 1:N) {
    for (k in 1:K) {
      y0_nat[i, k]    = exp(par[i, k][1]);
      y1_nat[i, k]    = y0_nat[i, k] + exp(par[i, k][2]);
      t1_nat[i, k]    = exp(par[i, k][3]);
      alpha_nat[i, k] = exp(par[i, k][4]);
      shape_nat[i, k] = exp(par[i, k][5]) + 1.0;
    }
  }
}
