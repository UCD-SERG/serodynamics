// ============================================================================
// STAN MODEL: Hierarchical Antibody Kinetics Model
// ----------------------------------------------------------------------------
// GOAL:
//   Estimate the antibody kinetics following infection using a hierarchical
//   (multilevel) Bayesian framework.
//
//   Each biomarker (antigen–isotype) has its own parameter distribution.
//   Each subject draws their individual antibody-response parameters from
//   these group-level distributions.
//
//   The antibody response is modeled as two phases:
//     (1) Growth during infection (up to a peak at time t₁)
//     (2) Decay/recovery after t₁
//
// ----------------------------------------------------------------------------
// MISSING DATA STRATEGY:
//   Stan cannot directly handle NA values in the data block.
//   To handle missing observations in antibody levels (logy) or sample times (smpl_t),
//   we use an indicator array `is_obs` (1 = observed, 0 = missing).
//   The likelihood is only applied to observed values, and missing values
//   can optionally be estimated as parameters if desired.
//
// ----------------------------------------------------------------------------
// MODEL STRUCTURE:
//   - Hierarchical priors (population → subject → observation)
//   - Each subject’s antibody curve is described by 5 parameters (log scale)
//     representing: baseline, rise, timing, decay, and shape.
//   - Observed log-antibody values are modeled as normally distributed
//     around the predicted curve, with antigen-specific precision.
//
// ============================================================================

data {
  // ----------------------------------------------------------------------------
  // DIMENSIONS
  // ----------------------------------------------------------------------------
  int<lower=1> nsubj;                 // number of subjects
  int<lower=1> n_antigen_isos;        // number of biomarkers (antigen-isotypes)
  int<lower=1> n_params;              // number of model parameters per antigen (usually 5)
  int<lower=1> max_nsmpl;             // max number of observations per subject
  int nsmpl[nsubj];                   // actual number of samples for each subject

  // ----------------------------------------------------------------------------
  // OBSERVED DATA
  // ----------------------------------------------------------------------------
  real smpl_t[nsubj, max_nsmpl];      // time since infection (continuous)
  real logy[nsubj, max_nsmpl, n_antigen_isos]; // observed log antibody levels

  // ----------------------------------------------------------------------------
  // MISSINGNESS INDICATOR (1 = observed, 0 = missing)
  // ----------------------------------------------------------------------------
  int<lower=0, upper=1> is_obs[nsubj, max_nsmpl, n_antigen_isos];

  // ----------------------------------------------------------------------------
  // HYPERPRIOR INFORMATION (FIXED INPUTS)
  // ----------------------------------------------------------------------------
  // These define weakly informative priors at the antigen (group) level
  vector[n_params] mu_hyp[n_antigen_isos];             // prior mean vector for mu_par
  matrix[n_params, n_params] prec_hyp[n_antigen_isos]; // prior precision matrix for mu_par
  matrix[n_params, n_params] omega[n_antigen_isos];    // scale matrix for Wishart prior
  real wishdf[n_antigen_isos];                         // degrees of freedom for Wishart
  vector[2] prec_logy_hyp[n_antigen_isos];             // (shape, rate) for gamma prior on precision
}

parameters {
  // ----------------------------------------------------------------------------
  // GROUP-LEVEL PARAMETERS
  // ----------------------------------------------------------------------------
  vector[n_params] mu_par[n_antigen_isos];             // mean of log-parameter distribution for each antigen
  matrix[n_params, n_params] prec_par[n_antigen_isos]; // precision (inverse covariance) matrix per antigen

  // ----------------------------------------------------------------------------
  // SUBJECT-LEVEL PARAMETERS (RANDOM EFFECTS)
  // ----------------------------------------------------------------------------
  // Each subject draws a set of kinetic parameters for each antigen
  // from the group-level multivariate normal distribution.
  vector[n_params] par[nsubj, n_antigen_isos];         // subject-specific parameters on log scale

  // ----------------------------------------------------------------------------
  // OBSERVATION-LEVEL PARAMETERS
  // ----------------------------------------------------------------------------
  real<lower=0> prec_logy[n_antigen_isos];             // precision (1/variance) for measurement error

  // ----------------------------------------------------------------------------
  // OPTIONAL: MISSING DATA IMPUTATION
  // ----------------------------------------------------------------------------
  // If you want Stan to impute missing values instead of skipping them,
  // declare them as parameters here.
  // Example:
  //   real<lower=0> smpl_t_mis[n_mis_t];  // missing time points
  //   real logy_mis[n_mis_y];             // missing antibody levels
}

transformed parameters {
  // ----------------------------------------------------------------------------
  // DERIVED QUANTITIES FOR INTERPRETATION
  // ----------------------------------------------------------------------------
  // Convert log-scale parameters to interpretable biological quantities.
  real y0[nsubj, n_antigen_isos];     // baseline antibody level (before infection)
  real y1[nsubj, n_antigen_isos];     // peak antibody level
  real t1[nsubj, n_antigen_isos];     // time to peak antibody
  real alpha[nsubj, n_antigen_isos];  // decay rate after peak
  real shape[nsubj, n_antigen_isos];  // shape parameter controlling recovery curvature
  real beta[nsubj, n_antigen_isos];   // antibody growth rate during infection
  real mu_logy[nsubj, max_nsmpl, n_antigen_isos]; // expected log-antibody at each observation

  // ----------------------------------------------------------------------------
  // COMPUTE EXPECTED VALUES (μ_logy)
  // ----------------------------------------------------------------------------
  for (subj in 1:nsubj) {
    for (a in 1:n_antigen_isos) {

      // --- Transform latent parameters ---
      // Parameters are stored in log form for stability.
      y0[subj, a]    = exp(par[subj, a, 1]);   // baseline level
      y1[subj, a]    = y0[subj, a] + exp(par[subj, a, 2]); // add positive increment for peak
      t1[subj, a]    = exp(par[subj, a, 3]);   // positive time to peak
      alpha[subj, a] = exp(par[subj, a, 4]);   // positive decay rate
      shape[subj, a] = exp(par[subj, a, 5]) + 1; // ensure >1 to avoid singularities

      // --- Derived growth rate ---
      beta[subj, a]  = log(y1[subj, a] / y0[subj, a]) / t1[subj, a];

      // --- Expected antibody trajectory ---
      for (obs in 1:nsmpl[subj]) {

        // PHASE 1: Infection/growth (t <= t₁)
        if (smpl_t[subj, obs] <= t1[subj, a]) {
          mu_logy[subj, obs, a] =
            log(y0[subj, a]) + beta[subj, a] * smpl_t[subj, obs];

        // PHASE 2: Recovery/decay (t > t₁)
        } else {
          mu_logy[subj, obs, a] =
            (1 / (1 - shape[subj, a])) *
            log(
              pow(y1[subj, a], (1 - shape[subj, a])) -
              (1 - shape[subj, a]) * alpha[subj, a] *
              (smpl_t[subj, obs] - t1[subj, a])
            );
        }
      }
    }
  }
}

model {
  // ----------------------------------------------------------------------------
  // HYPERPRIORS (GROUP LEVEL)
  // ----------------------------------------------------------------------------
  for (a in 1:n_antigen_isos) {
    // Prior for the mean vector of the antigen-level parameters
    mu_par[a] ~ multi_normal(mu_hyp[a], inverse_spd(prec_hyp[a]));

    // Prior for the precision matrix (Wishart prior on inverse covariance)
    prec_par[a] ~ wishart(wishdf[a], omega[a]);

    // Prior for measurement precision (Gamma distribution)
    // shape = prec_logy_hyp[a, 1], rate = prec_logy_hyp[a, 2]
    prec_logy[a] ~ gamma(prec_logy_hyp[a, 1], prec_logy_hyp[a, 2]);
  }

  // ----------------------------------------------------------------------------
  // SUBJECT-LEVEL PRIORS AND OBSERVATION MODEL
  // ----------------------------------------------------------------------------
  for (subj in 1:nsubj) {
    for (a in 1:n_antigen_isos) {

      // Random effects: each subject’s parameters drawn from the antigen’s distribution
      par[subj, a] ~ multi_normal(mu_par[a], inverse_spd(prec_par[a]));

      // Observation likelihood:
      // only use observed data (is_obs == 1) to avoid NA issues
      for (obs in 1:nsmpl[subj]) {
        if (is_obs[subj, obs, a] == 1) {
          logy[subj, obs, a] ~ normal(mu_logy[subj, obs, a],
                                      1 / sqrt(prec_logy[a]));
        }
      }
    }
  }
}

generated quantities {
  // ----------------------------------------------------------------------------
  // POSTERIOR PREDICTIVE CHECKING
  // ----------------------------------------------------------------------------
  // Generate replicated (simulated) log-antibody data
  real logy_rep[nsubj, max_nsmpl, n_antigen_isos];

  for (subj in 1:nsubj) {
    for (a in 1:n_antigen_isos) {
      for (obs in 1:nsmpl[subj]) {
        logy_rep[subj, obs, a] =
          normal_rng(mu_logy[subj, obs, a], 1 / sqrt(prec_logy[a]));
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
