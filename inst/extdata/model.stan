// -----------------------------------------------------------------------------
// Title: Antibody kinetics model (growth + decay phases)
// Converted from JAGS to Stan
// Handles missing smpl.t and logy data
// Based on Teunis et al., *Epidemics* 2016 (Equation 15 & 17)
// -----------------------------------------------------------------------------

data {
  // ------------------------
  // Study-level structure
  // ------------------------
  int<lower=1> nsubj;                  // number of subjects
  int<lower=1> n_antigen_isos;         // number of antigen-isotypes (e.g. IgG, IgA)
  int<lower=1> n_params;               // number of subject-level parameters (5)
  int<lower=1> max_nsmpl;              // maximum number of samples per subject

  // number of samples for each subject
  array[nsubj] int<lower=0> nsmpl;

  // ------------------------
  // Observed data (with missing values)
  // ------------------------

  // smpl_t_obs: time since infection for each sample
  // missing values will be ignored if mask == 1
  matrix[nsubj, max_nsmpl] smpl_t_obs;

  // logy_obs: log antibody concentrations for each observation
  // array[n_antigen_isos] matrix[nsubj, max_nsmpl] logy_obs;
  array[nsubj, max_nsmpl, n_antigen_isos] real logy_obs;

  // Binary masks (1 = missing, 0 = observed)
  array[nsubj, max_nsmpl] int<lower=0, upper=1> smpl_t_miss_mask;
  array[nsubj, max_nsmpl, n_antigen_isos] int<lower=0,upper=1> logy_miss_mask;

  // matrix[nsubj, max_nsmpl] smpl_t_miss_mask;
  // array[n_antigen_isos] matrix[nsubj, max_nsmpl] int<lower=0, upper=1> logy_miss_mask;

  // ------------------------
  // Hyperparameters for hierarchical priors
  // ------------------------

  // Mean of the biomarker-level parameter distributions
  matrix[n_antigen_isos, n_params] mu_hyp;

  // Precision matrices for biomarker-level parameters
  array[n_antigen_isos] matrix[n_params, n_params] prec_hyp;

  // Wishart/LKJ-related hyperpriors (for random effects covariance)
  array[n_antigen_isos] cov_matrix[n_params] omega;
  vector[n_antigen_isos] wishdf;

  // Hyperparameters for the measurement precision prior
  // prec_logy_hyp[i,1] = shape; prec_logy_hyp[i,2] = rate
  matrix[n_antigen_isos, 2] prec_logy_hyp;
}

parameters {
  // These are the parameters that we are monitoring...
  // ------------------------
  // Missing data imputation
  // ------------------------

  // Imputed sample times for missing smpl_t. 
  // Need to track imputation for missing data
  matrix<lower=0>[nsubj, max_nsmpl] smpl_t_miss;

  // Imputed log antibody levels for missing logy
  array[nsubj, max_nsmpl, n_antigen_isos] real logy_miss;

  // ------------------------
  // Hierarchical random effects
  // ------------------------

  // Subject-level parameters (random effects) for each biomarker
  // par_raw[p][subj, iso] is parameter p for subject subj and biomarker iso
  array[n_params] matrix[nsubj, n_antigen_isos] par_raw;

  // Mean vector (mu_par) for each biomarker's random-effect distribution
  matrix[n_antigen_isos, n_params] mu_par;

  // Cholesky factor of correlation for each biomarker’s random effect covariance
  array[n_antigen_isos] cholesky_factor_corr[n_params] L_par;

  // ------------------------
  // Measurement noise (likelihood SD)
  // ------------------------
  vector<lower=1e-3>[n_antigen_isos] sigma_logy;
}

transformed parameters {
  // Derived biological parameters for each subject × biomarker
  matrix[nsubj, n_antigen_isos] y0;      // baseline antibody level
  matrix[nsubj, n_antigen_isos] y1;      // peak antibody level
  matrix[nsubj, n_antigen_isos] t1;      // time to peak (end of infection)
  matrix[nsubj, n_antigen_isos] alpha;   // decay rate (ν in paper)
  matrix[nsubj, n_antigen_isos] shape;   // shape (r in paper)
  matrix[nsubj, n_antigen_isos] beta;    // growth rate (μ in paper)

  // Compute these deterministic quantities from par_raw
  for (subj in 1:nsubj) {
    for (iso in 1:n_antigen_isos) {
      // par_raw[, subj, iso] holds 5 parameters on log-scale
      y0[subj, iso]    = exp(par_raw[1][subj, iso]);
      y1[subj, iso]    = y0[subj, iso] + exp(par_raw[2][subj, iso]);
      t1[subj, iso]    = exp(par_raw[3][subj, iso]);
      alpha[subj, iso] = exp(par_raw[4][subj, iso]);
      shape[subj, iso] = exp(par_raw[5][subj, iso]) + 1.0; // +1 ensures r > 1
      beta[subj, iso]  = log(y1[subj, iso] / y0[subj, iso]) / t1[subj, iso];
    }
  }
}

model {
  // ---------------------------------------------------------------------------
  // 1. Priors for biomarker-level parameters (hyperpriors)
  // Corresponds to lines 70 - 75 of model.jags
  // ---------------------------------------------------------------------------

  for (iso in 1:n_antigen_isos) {
    // Biomarker-level means follow a multivariate normal
    mu_par[iso] ~ multi_normal_prec(mu_hyp[iso], prec_hyp[iso]);

    // LKJ prior for correlation matrix of random effects (instead of Wishart)
    L_par[iso] ~ lkj_corr_cholesky(2.0);  // weakly informative
    // May need to define this input as a parameter

    // Measurement noise prior (Gamma, consistent with precision prior in JAGS)
    sigma_logy[iso] ~ gamma(prec_logy_hyp[iso,1], prec_logy_hyp[iso,2]);
  }

  // ---------------------------------------------------------------------------
  // 2. Hierarchical random effects for each subject × biomarker
  // ---------------------------------------------------------------------------

  for (iso in 1:n_antigen_isos) {
    for (subj in 1:nsubj) {
      vector[n_params] par_vec;

      // Extract the 5 parameters for this subject and biomarker
      for (p in 1:n_params)
        par_vec[p] = par_raw[p][subj, iso];

      // Multivariate normal with Cholesky covariance (better for Stan)
      par_vec ~ multi_normal_cholesky(mu_par[iso]', L_par[iso]);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Priors for missing values (simple normal imputation priors)
  // ---------------------------------------------------------------------------

  // We place very weak priors on missing times and log-antibody levels
  to_vector(smpl_t_miss) ~ normal(0, 10);   // broad prior on missing times
  
  for (iso in 1:n_antigen_isos) {
    for (subj in 1:nsubj) {
      for (obs in 1:max_nsmpl) {
        logy_miss[subj, obs, iso] ~ normal(0, 10);
        }
        }
        }

  // to_vector(logy_miss) ~ normal(0, 10);     // broad prior on missing log-antibody levels

  // ---------------------------------------------------------------------------
  // 4. Likelihood: observed + imputed antibody levels over time
  // ---------------------------------------------------------------------------

  for (subj in 1:nsubj) {
    for (iso in 1:n_antigen_isos) {
      for (obs in 1:nsmpl[subj]) {

        // -------------------------------------------------
        // Handle missing data by substituting imputed values
        // -------------------------------------------------
        // This code is an if then statement to say if the data is missing, use
        // the imputed code, if not, use the observation. This applies to both
        // smpl_t values and logy values. 
        real t_obs = (smpl_t_miss_mask[subj, obs] == 1)
                      ? smpl_t_miss[subj, obs] 
                      : smpl_t_obs[subj, obs];
        
        real logy_val = (logy_miss_mask[subj, obs, iso] == 1)
                    ? logy_miss[subj, obs, iso]
                    : logy_obs[subj, obs, iso];
                    

        // -------------------------------------------------
        // Compute expected log antibody concentration μ_logy
        // according to infection phase
        // -------------------------------------------------
        real mu_logy;

        if (t_obs <= t1[subj,iso]) {
          // ----- ACTIVE INFECTION PHASE -----
          // log(y(t)) = log(y0) + β * t
          mu_logy = log(y0[subj,iso]) + beta[subj,iso] * t_obs;

        } else {
          // ----- RECOVERY PHASE -----
          // log(y(t)) = [1 / (1 - r)] * log( y1^(1-r) - (1 - r)*α*(t - t1) )
          mu_logy = (1 / (1 - shape[subj,iso])) *
            log(fmax(pow(y1[subj,iso], (1 - shape[subj,iso])) -
                 (1 - shape[subj,iso]) * alpha[subj,iso] * 
                 (t_obs - t1[subj,iso]), 1e-8));
        }

        // -------------------------------------------------
        // Likelihood: log(y) ~ Normal(μ_logy, σ_logy)
        // -------------------------------------------------
        logy_val ~ normal(mu_logy, sigma_logy[iso]);
      }
    }
  }
}


