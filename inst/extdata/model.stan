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



// This is the old model
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


//data {
  // -------------------------------------------------------------
  // Dimensions and indexing
  // -------------------------------------------------------------
//  int<lower=1> nsubj;              // number of subjects
//  int<lower=1> n_antigen_isos;     // number of biomarkers (antigen-isotypes)
//  int<lower=1> n_params;           // number of parameters per antigen (5)
//  int<lower=1> max_nsmpl;          // maximum number of observations per subject. 
                                   // This is to create a rectangular data frame input nsubj x max_nsmpl
//  int nsmpl[nsubj];                // actual number of samples per subject

  // -------------------------------------------------------------
  // Observed data
  // -------------------------------------------------------------
//  real smpl_t[nsubj, max_nsmpl];   // time since infection for each sample
//  real logy[nsubj, max_nsmpl, n_antigen_isos]; // observed log antibody levels
  
   // Observed data indices and values
  // -------------------------------------------------------------
//  int<lower=0> n_obs_logy; // number of observed logy values
//  int<lower=0> n_miss_logy;
//  int<lower=1, upper=nsubj> subj_obs_logy[n_obs_logy];
//  int<lower=1, upper=max_nsmpl> smpl_obs_logy[n_obs_logy];
//  int<lower=1, upper=n_antigen_isos> ag_obs_logy[n_obs_logy];
//  vector[n_obs_logy] logy_obs;

//  int<lower=0> n_obs_smpl_t; // number of observed smpl_t
//  int<lower=0> n_miss_smpl_t;
//  int<lower=1, upper=nsubj> subj_obs_smpl_t[n_obs_smpl_t];
//  int<lower=1, upper=max_nsmpl> smpl_obs_smpl_t[n_obs_smpl_t];
//  matrix[nsubj, max_nsmpl] smpl_t_obs; // observed where available

  // -------------------------------------------------------------
  // Hyperprior parameters (known inputs)
  // -------------------------------------------------------------
//  vector[n_params] mu_hyp[n_antigen_isos];          // prior mean for mu_par
//  matrix[n_params, n_params] prec_hyp[n_antigen_isos]; // precision for mu_par prior
//  matrix[n_params, n_params] omega[n_antigen_isos]; // Wishart scale matrix for prec_par
//  real wishdf[n_antigen_isos];                      // degrees of freedom for Wishart
//  vector[2] prec_logy_hyp[n_antigen_isos];          // shape/rate for gamma prior on measurement precision
//}

//parameters {
  // -------------------------------------------------------------
  // Group-level parameters
  // -------------------------------------------------------------
//  vector[n_params] mu_par[n_antigen_isos];            // mean of parameter distribution for each antigen
//  matrix[n_params, n_params] prec_par[n_antigen_isos]; // precision matrix for each antigen’s parameter set

  // -------------------------------------------------------------
  // Subject-level random effects (log-scale)
  // -------------------------------------------------------------
//  vector[n_params] par[nsubj, n_antigen_isos]; // log parameters per subject and antigen

  // -------------------------------------------------------------
  // Observation precision (for measurement error)
  // -------------------------------------------------------------
//  real<lower=0> prec_logy[n_antigen_isos];  // precision of measurement noise
//}

//transformed parameters {
  // -------------------------------------------------------------
  // Derived quantities for biological interpretation
  // -------------------------------------------------------------
//  real y0[nsubj, n_antigen_isos];     // baseline antibody level
//  real y1[nsubj, n_antigen_isos];     // peak antibody level
//  real t1[nsubj, n_antigen_isos];     // time to peak
//  real alpha[nsubj, n_antigen_isos];  // decay rate (nu)
//  real shape[nsubj, n_antigen_isos];  // recovery shape parameter (r)
//  real beta[nsubj, n_antigen_isos];   // growth rate (infection phase)
//  real mu_logy[nsubj, max_nsmpl, n_antigen_isos]; // expected log antibody

  // -------------------------------------------------------------
  // Generate all deterministic quantities
  // -------------------------------------------------------------
//  for (subj in 1:nsubj) {
//    for (a in 1:n_antigen_isos) {
      // Reparameterize latent parameters (original JAGS lines)
//      y0[subj, a]    = exp(par[subj, a, 1]);
//      y1[subj, a]    = y0[subj, a] + exp(par[subj, a, 2]);
//      t1[subj, a]    = exp(par[subj, a, 3]);
//      alpha[subj, a] = exp(par[subj, a, 4]);
//      shape[subj, a] = exp(par[subj, a, 5]) + 1;

      // Equation 17: antibody growth rate during infection
//      beta[subj, a]  = log(y1[subj, a] / y0[subj, a]) / t1[subj, a];

      // For each observation, compute expected log-antibody level
//      for (obs in 1:nsmpl[subj]) {
//        if (smpl_t[subj, obs] <= t1[subj, a]) {
          // Active infection phase (equation 15, case t <= t1)
//          mu_logy[subj, obs, a] =
//            log(y0[subj, a]) + beta[subj, a] * smpl_t[subj, obs];
//        } else {
          // Recovery phase (equation 15, case t > t1)
//          mu_logy[subj, obs, a] = (1 / (1 - shape[subj, a])) * 
//          log(pow(y1[subj, a], (1 - shape[subj, a])) - (1 - shape[subj, a]) *
//              alpha[subj, a] *
//              (smpl_t[subj, obs] - t1[subj, a])
//            );
//        }
//      }
//    }
//  }
//}

//model {
  // -------------------------------------------------------------
  // Hyperpriors
  // -------------------------------------------------------------
//  for (a in 1:n_antigen_isos) {
    // Prior for group means of parameters
//    mu_par[a] ~ multi_normal(mu_hyp[a], inverse_spd(prec_hyp[a]));

    // Prior for precision matrices (Wishart)
//    prec_par[a] ~ wishart(wishdf[a], omega[a]);
    // Could also use: L_par[a] ~ lkj_corr_cholesky(2);
        //sigma_par[a] ~ cauchy(0, 2.5); LKJ priors more common in stan

    // Prior for measurement precision (gamma)
//    prec_logy[a] ~ gamma(prec_logy_hyp[a, 1], prec_logy_hyp[a, 2]);
    // Can rewrite as sigma_logy[a] ~ cauchy(0, 2); Stan prefers sds
//  }

  // -------------------------------------------------------------
  // Subject-level priors and observation likelihood
  // -------------------------------------------------------------
//  for (subj in 1:nsubj) {
//    for (a in 1:n_antigen_isos) {
      // Random effects: multivariate normal prior on subject parameters
//      par[subj, a] ~ multi_normal(mu_par[a], inverse_spd(prec_par[a]));

      // Observation model: log-antibody levels
//      for (obs in 1:nsmpl[subj]) {
//        logy[subj, obs, a] ~ normal(mu_logy[subj, obs, a],
//                                    1 / sqrt(prec_logy[a]));
//      }
//    }
//  }
//}
