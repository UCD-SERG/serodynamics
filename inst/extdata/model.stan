// Stan model for antibody dynamics
// Translated from JAGS model.jags
// Models longitudinal antibody responses with hierarchical priors

data {
  int<lower=1> nsubj;                             // number of subjects
  int<lower=1> n_antigen_isos;                    // number of biomarkers
  int<lower=1> n_params;                          // number of parameters (5)
  array[nsubj] int<lower=1> nsmpl;                // number of samples per subject
  int<lower=1> max_nsmpl;                         // maximum number of samples
  array[nsubj, max_nsmpl] real smpl_t;            // sample times
  array[nsubj, max_nsmpl, n_antigen_isos] real logy;  // log antibody measurements
  
  // Hyperpriors
  array[n_antigen_isos] vector[n_params] mu_hyp;           // hyperprior means
  array[n_antigen_isos] matrix[n_params, n_params] prec_hyp;  // hyperprior precision
  array[n_antigen_isos] matrix[n_params, n_params] omega;      // Wishart scale matrix
  array[n_antigen_isos] real<lower=n_params> wishdf;          // Wishart degrees of freedom
  array[n_antigen_isos, 2] real<lower=0> prec_logy_hyp;       // gamma hyperpriors for precision
}

transformed data {
  // Convert precision matrices to covariance matrices for Stan
  array[n_antigen_isos] matrix[n_params, n_params] sigma_hyp;
  array[n_antigen_isos] matrix[n_params, n_params] omega_inv;
  
  for (k in 1:n_antigen_isos) {
    sigma_hyp[k] = inverse(prec_hyp[k]);
    omega_inv[k] = inverse(omega[k]);
  }
}

parameters {
  // Subject-level parameters (transformed scale)
  array[nsubj, n_antigen_isos] vector[n_params] par;
  
  // Population-level parameters
  array[n_antigen_isos] vector[n_params] mu_par;
  
  // Covariance matrices (Stan uses covariance, not precision)
  array[n_antigen_isos] cov_matrix[n_params] Sigma_par;
  
  // Observation precision (measurement error)
  array[n_antigen_isos] real<lower=0> prec_logy;
}

transformed parameters {
  // Subject-level parameters on natural scale
  array[nsubj, n_antigen_isos] real<lower=0> y0;
  array[nsubj, n_antigen_isos] real<lower=0> y1;
  array[nsubj, n_antigen_isos] real<lower=0> t1;
  array[nsubj, n_antigen_isos] real<lower=0> alpha;
  array[nsubj, n_antigen_isos] real<lower=1> shape;
  
  // Growth rate parameter
  array[nsubj, n_antigen_isos] real beta;
  
  // Transform parameters
  for (subj in 1:nsubj) {
    for (k in 1:n_antigen_isos) {
      y0[subj, k] = exp(par[subj, k][1]);
      y1[subj, k] = y0[subj, k] + exp(par[subj, k][2]);  // par[,,2] is log(y1-y0)
      t1[subj, k] = exp(par[subj, k][3]);
      alpha[subj, k] = exp(par[subj, k][4]);
      shape[subj, k] = exp(par[subj, k][5]) + 1;
      
      // Compute growth rate
      beta[subj, k] = log(y1[subj, k] / y0[subj, k]) / t1[subj, k];
    }
  }
}

model {
  // Hyperpriors
  for (k in 1:n_antigen_isos) {
    mu_par[k] ~ multi_normal(mu_hyp[k], sigma_hyp[k]);
    Sigma_par[k] ~ inv_wishart(wishdf[k], omega_inv[k]);
    prec_logy[k] ~ gamma(prec_logy_hyp[k, 1], prec_logy_hyp[k, 2]);
  }
  
  // Subject-level priors
  for (subj in 1:nsubj) {
    for (k in 1:n_antigen_isos) {
      par[subj, k] ~ multi_normal(mu_par[k], Sigma_par[k]);
    }
  }
  
  // Likelihood
  for (subj in 1:nsubj) {
    for (obs in 1:nsmpl[subj]) {
      for (k in 1:n_antigen_isos) {
        real mu_logy;
        real sigma_logy;
        
        sigma_logy = 1.0 / sqrt(prec_logy[k]);
        
        // Determine phase: active infection or recovery
        if (smpl_t[subj, obs] <= t1[subj, k]) {
          // Active infection period (t <= t1)
          mu_logy = log(y0[subj, k]) + beta[subj, k] * smpl_t[subj, obs];
        } else {
          // Recovery period (t > t1)
          real shape_term = shape[subj, k];
          real y1_val = y1[subj, k];
          real t_diff = smpl_t[subj, obs] - t1[subj, k];
          real alpha_val = alpha[subj, k];
          
          mu_logy = (1.0 / (1.0 - shape_term)) * 
                    log(y1_val^(1.0 - shape_term) - 
                        (1.0 - shape_term) * alpha_val * t_diff);
        }
        
        logy[subj, obs, k] ~ normal(mu_logy, sigma_logy);
      }
    }
  }
}
