data {
  int<lower=1> nsubj;
  int<lower=1> n_iso;                # n_antigen_isos
  int<lower=1> n_params;             # number of params per subject (5 in your model)
  int<lower=1> max_nsmpl;
  int nsmpl[nsubj];                  # number of samples per subject
  real smpl_t[nsubj, max_nsmpl];     # sample times (use NA or some value for unused entries but nsmpl controls)
  real logy[nsubj, max_nsmpl, n_iso]; # observed log(Y), unused entries can be anything
  
  # Hyperprior inputs (make these informative for your problem):
    # prior means for the per-iso population means of the transformed parameters (on the par[] scale)
  matrix[n_iso, n_params] mu_par_prior_mean;
  matrix[n_iso, n_params] mu_par_prior_sd; # positive sds (can be relatively large for weakly informative)
  real<lower=0> sigma_logy_prior_scale[n_iso]; # prior scale for observation sd (half-Cauchy / student-t scale)
  real<lower=0> lkj_eta; # LKJ shape parameter for correlations (e.g. 1 = uniform, >1 concentrates toward identity)
}

parameters {
  # population-level location (per-iso)
  matrix[n_iso, n_params] mu_par;
  
  # non-centered parameterization for subject-level par:
    # for each iso: cholesky_factor_corr * (sigma_par .* par_raw) + mu_par
  cholesky_factor_corr[n_params] L_corr[n_iso];
  vector<lower=0>[n_params] sigma_par[n_iso];
  
  # standard normal raw variates for non-centered MVN
  # indexed [subj, iso] with vector of length n_params
  vector[n_params] par_raw[nsubj, n_iso];
  
  # observation noise (sd) per iso
  # Use half-normal or student_t scale; here we use positive scale parameter
  real<lower=0> sigma_logy[n_iso];
}

transformed parameters {
  # per-subject/per-iso parameter on original par[] scale
  # par[subj, iso, p]
  # We'll store as array of vectors for convenience
  vector[n_params] par[nsubj, n_iso];

  # derived biological quantities (matching your JAGS transforms)
  real y0[nsubj, n_iso];
  real y1[nsubj, n_iso];
  real t1[nsubj, n_iso];
  real alpha[nsubj, n_iso];
  real shape[nsubj, n_iso];
  real beta[nsubj, n_iso];

  # expected logy for each obs
  real mu_logy[nsubj, max_nsmpl, n_iso];

  for (iso in 1:n_iso) {
    for (s in 1:nsubj) {
      # non-centered -> centered
      par[s, iso] = mu_par[iso]' + diag_pre_multiply(sigma_par[iso], L_corr[iso]) * par_raw[s, iso];
  
  # back-transform to biologically-interpretable parameters
  # NOTE: par indexing follows your JAGS: 1=y0_log, 2=log(y1-y0), 3=log(t1), 4=log(alpha), 5=log(shape-1)
  y0[s, iso]    = exp(par[s, iso][1]);
  y1[s, iso]    = y0[s, iso] + exp(par[s, iso][2]); # par[,,2] = log(y1 - y0)
  t1[s, iso]    = exp(par[s, iso][3]);
  alpha[s, iso] = exp(par[s, iso][4]);
  shape[s, iso] = exp(par[s, iso][5]) + 1.0;
  
  
   growth rate beta = log(y1 / y0) / t1
  beta[s, iso] = log(y1[s, iso] / y0[s, iso]) / t1[s, iso];
  
  # compute expected log y for each sample time (handles both phases)
  for (obs in 1:max_nsmpl) {
    if (obs <= nsmpl[s]) {
      real tt = smpl_t[s, obs];
      if (tt <= t1[s, iso]) {
        mu_logy[s, obs, iso] = log(y0[s, iso]) + beta[s, iso] * tt;
      } else {
        # recovery formula from your JAGS code:
          mu_logy[s, obs, iso] = 1.0 / (1.0 - shape[s, iso]) *
            log( pow(y1[s, iso], 1.0 - shape[s, iso])
                 - (1.0 - shape[s, iso]) * alpha[s, iso] * (tt - t1[s, iso]) );
      }
    } else {
      mu_logy[s, obs, iso] = 0; # unused entry
    }
  }
}
}
}

model {
  # -----------------------
    # Hyperpriors / population priors
  # -----------------------
    for (iso in 1:n_iso) {
      # population means: allow user-specified prior means & sds
      for (p in 1:n_params) {
        mu_par[iso, p] ~ normal(mu_par_prior_mean[iso, p], mu_par_prior_sd[iso, p]);
      }
      
      # scales (SDs) of the multivariate random effects: weakly informative half-normal
      sigma_par[iso] ~ normal(0, 1.0); # positive vector via declaration, treat as half-normal-ish
      # correlation (Cholesky factor) via LKJ prior
      L_corr[iso] ~ lkj_corr_cholesky(lkj_eta);
    }
  
  # observation noise priors
  for (iso in 1:n_iso) {
    sigma_logy[iso] ~ cauchy(0, sigma_logy_prior_scale[iso]); # half-Cauchy on positive
  }
  
  # -----------------------
    # Subject-level random effects (non-centered)
  # and likelihood
  # -----------------------
    for (iso in 1:n_iso) {
      for (s in 1:nsubj) {
        # par_raw are standard normal a priori (non-centered param)
        par_raw[s, iso] ~ normal(0, 1);
        
        # likelihood: vectorized across observed samples for this subj/iso
        for (obs in 1:nsmpl[s]) {
          logy[s, obs, iso] ~ normal(mu_logy[s, obs, iso], sigma_logy[iso]);
        }
      }
    }
}

generated quantities {
  # return full covariance matrices for inspection
  cov_matrix[n_params] Sigma_par[n_iso];
  for (iso in 1:n_iso) {
    matrix[n_params, n_params] R = multiply_lower_tri_self_transpose(L_corr[iso]);
    # diag_pre_multiply(sigma, L) * diag_pre_multiply(sigma, L)' = (diag(sigma) * R * diag(sigma))
    Sigma_par[iso] = diag_matrix(sigma_par[iso]) * R * diag_matrix(sigma_par[iso]);
  }
}