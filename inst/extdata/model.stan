// ============================================================================
// STAN MODEL: Antibody Kinetics with Hierarchical Parameters
// ----------------------------------------------------------------------------
// This model estimates antibody kinetics (growth + decay) using a 
// hierarchical Bayesian structure across subjects and antigen-isotypes.
//
// Each biomarker (antigen-isotype) has its own set of parameters describing
// the time course of antibody response following infection.
//
// Missing data in `logy` or `smpl_t` can be handled by either:
//   1. Excluding those observations via an indicator matrix, or
//   2. Treating missing times/values as parameters to estimate (see notes).
// ============================================================================


data {
  // -------------------------------------------------------------
  // Dimensions and indexing
  // -------------------------------------------------------------
  int<lower=1> nsubj;              // number of subjects
  int<lower=1> n_antigen_isos;     // number of biomarkers (antigen-isotypes)
  int<lower=1> n_params;           // number of parameters per antigen (5)
  int<lower=1> max_nsmpl;          // maximum number of observations per subject. 
                                   // This is to create a rectangular data frame input nsubj x max_nsmpl
  int nsmpl[nsubj];                // actual number of samples per subject

  // -------------------------------------------------------------
  // Observed data
  // -------------------------------------------------------------
  real smpl_t[nsubj, max_nsmpl];   // time since infection for each sample
  real logy[nsubj, max_nsmpl, n_antigen_isos]; // observed log antibody levels
  
   // Observed data indices and values
  // -------------------------------------------------------------
  int<lower=0> n_obs_logy; // number of observed logy values
  int<lower=0> n_miss_logy;
  int<lower=1, upper=nsubj> subj_obs_logy[n_obs_logy];
  int<lower=1, upper=max_nsmpl> smpl_obs_logy[n_obs_logy];
  int<lower=1, upper=n_antigen_isos> ag_obs_logy[n_obs_logy];
  vector[n_obs_logy] logy_obs;

  int<lower=0> n_obs_smpl_t; // number of observed smpl_t
  int<lower=0> n_miss_smpl_t;
  int<lower=1, upper=nsubj> subj_obs_smpl_t[n_obs_smpl_t];
  int<lower=1, upper=max_nsmpl> smpl_obs_smpl_t[n_obs_smpl_t];
  matrix[nsubj, max_nsmpl] smpl_t_obs; // observed where available

  // -------------------------------------------------------------
  // Hyperprior parameters (known inputs)
  // -------------------------------------------------------------
  vector[n_params] mu_hyp[n_antigen_isos];          // prior mean for mu_par
  matrix[n_params, n_params] prec_hyp[n_antigen_isos]; // precision for mu_par prior
  matrix[n_params, n_params] omega[n_antigen_isos]; // Wishart scale matrix for prec_par
  real wishdf[n_antigen_isos];                      // degrees of freedom for Wishart
  vector[2] prec_logy_hyp[n_antigen_isos];          // shape/rate for gamma prior on measurement precision
}

parameters {
  // -------------------------------------------------------------
  // Group-level parameters
  // -------------------------------------------------------------
  vector[n_params] mu_par[n_antigen_isos];            // mean of parameter distribution for each antigen
  matrix[n_params, n_params] prec_par[n_antigen_isos]; // precision matrix for each antigen’s parameter set

  // -------------------------------------------------------------
  // Subject-level random effects (log-scale)
  // -------------------------------------------------------------
  vector[n_params] par[nsubj, n_antigen_isos]; // log parameters per subject and antigen

  // -------------------------------------------------------------
  // Observation precision (for measurement error)
  // -------------------------------------------------------------
  real<lower=0> prec_logy[n_antigen_isos];  // precision of measurement noise
}

transformed parameters {
  // -------------------------------------------------------------
  // Derived quantities for biological interpretation
  // -------------------------------------------------------------
  real y0[nsubj, n_antigen_isos];     // baseline antibody level
  real y1[nsubj, n_antigen_isos];     // peak antibody level
  real t1[nsubj, n_antigen_isos];     // time to peak
  real alpha[nsubj, n_antigen_isos];  // decay rate (nu)
  real shape[nsubj, n_antigen_isos];  // recovery shape parameter (r)
  real beta[nsubj, n_antigen_isos];   // growth rate (infection phase)
  real mu_logy[nsubj, max_nsmpl, n_antigen_isos]; // expected log antibody

  // -------------------------------------------------------------
  // Generate all deterministic quantities
  // -------------------------------------------------------------
  for (subj in 1:nsubj) {
    for (a in 1:n_antigen_isos) {
      // Reparameterize latent parameters (original JAGS lines)
      y0[subj, a]    = exp(par[subj, a, 1]);
      y1[subj, a]    = y0[subj, a] + exp(par[subj, a, 2]);
      t1[subj, a]    = exp(par[subj, a, 3]);
      alpha[subj, a] = exp(par[subj, a, 4]);
      shape[subj, a] = exp(par[subj, a, 5]) + 1;

      // Equation 17: antibody growth rate during infection
      beta[subj, a]  = log(y1[subj, a] / y0[subj, a]) / t1[subj, a];

      // For each observation, compute expected log-antibody level
      for (obs in 1:nsmpl[subj]) {
        if (smpl_t[subj, obs] <= t1[subj, a]) {
          // Active infection phase (equation 15, case t <= t1)
          mu_logy[subj, obs, a] =
            log(y0[subj, a]) + beta[subj, a] * smpl_t[subj, obs];
        } else {
          // Recovery phase (equation 15, case t > t1)
          mu_logy[subj, obs, a] = (1 / (1 - shape[subj, a])) * 
          log(pow(y1[subj, a], (1 - shape[subj, a])) - (1 - shape[subj, a]) *
              alpha[subj, a] *
              (smpl_t[subj, obs] - t1[subj, a])
            );
        }
      }
    }
  }
}

model {
  // -------------------------------------------------------------
  // Hyperpriors
  // -------------------------------------------------------------
  for (a in 1:n_antigen_isos) {
    // Prior for group means of parameters
    mu_par[a] ~ multi_normal(mu_hyp[a], inverse_spd(prec_hyp[a]));

    // Prior for precision matrices (Wishart)
    prec_par[a] ~ wishart(wishdf[a], omega[a]);
    // Could also use: L_par[a] ~ lkj_corr_cholesky(2);
        //sigma_par[a] ~ cauchy(0, 2.5); LKJ priors more common in stan

    // Prior for measurement precision (gamma)
    prec_logy[a] ~ gamma(prec_logy_hyp[a, 1], prec_logy_hyp[a, 2]);
    // Can rewrite as sigma_logy[a] ~ cauchy(0, 2); Stan prefers sds
  }

  // -------------------------------------------------------------
  // Subject-level priors and observation likelihood
  // -------------------------------------------------------------
  for (subj in 1:nsubj) {
    for (a in 1:n_antigen_isos) {
      // Random effects: multivariate normal prior on subject parameters
      par[subj, a] ~ multi_normal(mu_par[a], inverse_spd(prec_par[a]));

      // Observation model: log-antibody levels
      for (obs in 1:nsmpl[subj]) {
        logy[subj, obs, a] ~ normal(mu_logy[subj, obs, a],
                                    1 / sqrt(prec_logy[a]));
      }
    }
  }
}
