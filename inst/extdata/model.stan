// ============================================================================
// model.stan  -- Stan implementation of the serodynamics within-host model
// Author: Kwan Ho Lee
//
// Within-host antibody kinetics (Teunis et al., Epidemics 2016, eq. 15), fit
// hierarchically over subjects and antigen-isotypes. This is the Stan version
// of model.jags. It reads the SAME data and priors as the JAGS model (the
// output of prep_priors_stan(): mu_hyp, prec_hyp, omega, wishdf,
// prec_logy_hyp), so run_mod() (JAGS) and run_mod_stan() (Stan) fit the same
// model and their posteriors can be compared directly. I derive the HMC
// reparameterizations in the companion note model_stan_transform_from_jags.md.
//
//   Exact (same contribution to the log-posterior as JAGS):
//     - two-phase kinetic curve (active + recovery)     [functions{} + model{}]
//     - population mean        mu.par ~ dmnorm           [multi_normal_prec]
//     - measurement precision  prec.logy ~ dgamma        [gamma]
//     - subject random effects par ~ dmnorm              [non-centered, exact]
//
//   Reparameterized (matched to JAGS, not a literal translation):
//     - between-subject covariance  prec.par ~ dwish     [LKJ + lognormal]
//       The inverse-Wishart is badly conditioned under HMC (tree-depth
//       saturation, R-hat ~ 2.5), so I split the covariance into an independent
//       scale (lognormal, matched to the Wishart's inverse-gamma margins) and a
//       correlation (LKJ, matched to its correlation spread). The matching
//       constants are computed in transformed data below from omega and wishdf.
//
//   Numerically safe: the recovery-phase log-curve uses log1p, which removes
//     both the log-of-negative and the shape -> 1 removable singularity.
// ============================================================================

functions {
  /* log y(t) for BOTH phases. Algebraically identical to model.jags.

     JAGS active branch (t <= t1):
        log(y0) + beta * t,   beta = log(y1/y0)/t1 = (log_y1 - log_y0)/t1

     JAGS recovery branch (t > t1):
        (1/(1-r)) * log( y1^(1-r) - (1-r)*alpha*(t-t1) )
     With a = r - 1 > 0, since (1-r) = -a:
        y1^(1-r) - (1-r)*alpha*(t-t1)
          = y1^(-a) + a*alpha*(t-t1)
          = y1^(-a) * ( 1 + a*alpha*(t-t1)*y1^a )
        => (1/(1-r)) * log(...) = log_y1 - log1p(a*alpha*(t-t1)*y1^a) / a
     The log1p argument is >= 0 (no log-of-negative), and the expression tends
     to  log_y1 - alpha*(t-t1)  smoothly as r -> 1 (no 1/(1-r) blow-up).        */
  real log_two_phase(real t,
                     real log_y0, real log_y1, real y1,
                     real t1, real alpha, real shape) {
    if (t <= t1) {
      return log_y0 + (log_y1 - log_y0) / t1 * t;          // active phase
    }
    real a = shape - 1;                                    // recovery, a > 0
    return log_y1 - log1p(a * alpha * (t - t1) * pow(y1, a)) / a;
  }
}

data {
  int<lower=1> nsubj;                                       // # subjects
  int<lower=1> n_antigen_isos;                             // # biomarkers
  int<lower=1> n_params;                                    // = 5
  array[nsubj] int<lower=0> nsmpl;                          // obs per subject (>= 0)
  int<lower=1> max_nsmpl;                                   // max obs per subject
  array[nsubj, max_nsmpl] real smpl_t;                      // sample times
  array[nsubj, max_nsmpl, n_antigen_isos] real logy;       // log measurements

  // -------- Priors, identical to model.jags (from prep_priors_stan) -----------
  array[n_antigen_isos] vector[n_params] mu_hyp;            // dmnorm mean
  array[n_antigen_isos] matrix[n_params, n_params] prec_hyp;// dmnorm PRECISION
  array[n_antigen_isos] matrix[n_params, n_params] omega;   // dwish scale matrix
  array[n_antigen_isos] real<lower=n_params> wishdf;        // dwish degrees of freedom
  array[n_antigen_isos, 2] real<lower=0> prec_logy_hyp;     // dgamma(shape, rate)
}

transformed data {
  // Moment-match the JAGS inverse-Wishart covariance prior to an LKJ +
  // lognormal factorization (derivation in model_stan_transform_from_jags.md).
  //
  // JAGS places a Wishart on the PRECISION: prec.par ~ dwish(omega, wishdf).
  // Hence the covariance Sigma = prec.par^-1 is INVERSE-WISHART with scale =
  // omega ITSELF (NOT omega^-1 -- this sign of the inversion was the original
  // port bug). Each diagonal Sigma_jj is then marginally
  //     Sigma_jj ~ inverse-gamma(shape = (wishdf - p + 1)/2, scale = omega_jj/2),
  // so sigma_j = sqrt(Sigma_jj) has log-mean/sd matched by a lognormal below.
  // The LKJ shape eta is matched ANALYTICALLY to the inverse-Wishart marginal
  // correlation spread (Barnard, McCulloch & Meng 2000):
  //     Var(corr) = 1/(wishdf - p + 2)  ==  1/(2*eta + p - 1)
  //     =>  eta = (wishdf - 2p + 3)/2.   (e.g. wishdf=20, p=5 -> eta = 6.5)
  array[n_antigen_isos] vector[n_params] sigma_meanlog;
  array[n_antigen_isos] vector<lower=0>[n_params] sigma_sdlog;
  array[n_antigen_isos] real<lower=0> eta;
  for (k in 1:n_antigen_isos) {
    real shp = (wishdf[k] - n_params + 1) / 2.0;
    vector[n_params] om_diag = diagonal(omega[k]);          // = diag(omega)
    for (j in 1:n_params) {
      sigma_meanlog[k][j] = 0.5 * (log(om_diag[j] / 2.0) - digamma(shp));
    }
    sigma_sdlog[k] = rep_vector(0.5 * sqrt(trigamma(shp)), n_params);
    // 0.1 floor: for wishdf < 2p-1 the inverse-Wishart correlation is wider
    // than any LKJ can represent; clamp to the widest sensible LKJ. The default
    // (wishdf=20) and modifiable-prior values are well above the floor.
    eta[k] = fmax((wishdf[k] - 2.0 * n_params + 3.0) / 2.0, 0.1);
  }
}

parameters {
  array[n_antigen_isos] vector[n_params] mu_par;            // population means
  array[n_antigen_isos] vector<lower=0>[n_params] sigma_par;// between-subj SDs (scale)
  array[n_antigen_isos] cholesky_factor_corr[n_params] L_corr; // corr Cholesky
  array[nsubj, n_antigen_isos] vector[n_params] z;          // non-centered N(0,1)
  array[n_antigen_isos] real<lower=0> prec_logy;            // measurement precision
}

transformed parameters {
  array[nsubj, n_antigen_isos] vector[n_params] par;        // subject params (log scale)
  array[nsubj, n_antigen_isos] real<lower=0> y0;
  array[nsubj, n_antigen_isos] real<lower=0> y1;
  array[nsubj, n_antigen_isos] real<lower=0> t1;
  array[nsubj, n_antigen_isos] real<lower=0> alpha;
  array[nsubj, n_antigen_isos] real<lower=1> shape;

  for (subj in 1:nsubj) {
    for (k in 1:n_antigen_isos) {
      // NON-CENTERED (Matt trick) -- distributionally IDENTICAL to the JAGS draw
      //   par ~ MVN(mu_par[k], Sigma_k),  Sigma_k = diag(sigma) R diag(sigma),
      //   R = L_corr L_corr'.  Here par = mu + diag(sigma) L_corr z, z ~ N(0,I).
      par[subj, k] = mu_par[k]
        + diag_pre_multiply(sigma_par[k], L_corr[k]) * z[subj, k];

      // JAGS random-effects transform (exact):
      y0[subj, k]    = exp(par[subj, k][1]);
      y1[subj, k]    = y0[subj, k] + exp(par[subj, k][2]);  // par[,,2] = log(y1 - y0)
      t1[subj, k]    = exp(par[subj, k][3]);
      alpha[subj, k] = exp(par[subj, k][4]);
      shape[subj, k] = exp(par[subj, k][5]) + 1;            // r = exp(par5) + 1 > 1
    }
  }
}

model {
  // ---- Hyperpriors -----------------------------------------------------------
  for (k in 1:n_antigen_isos) {
    mu_par[k]    ~ multi_normal_prec(mu_hyp[k], prec_hyp[k]); // = JAGS dmnorm (precision)
    sigma_par[k] ~ lognormal(sigma_meanlog[k], sigma_sdlog[k]); // Wishart-matched scale
    L_corr[k]    ~ lkj_corr_cholesky(eta[k]);                // Wishart-matched correlation
    prec_logy[k] ~ gamma(prec_logy_hyp[k, 1], prec_logy_hyp[k, 2]); // = JAGS dgamma
  }

  // ---- Subject random effects (non-centered) ---------------------------------
  for (subj in 1:nsubj) {
    for (k in 1:n_antigen_isos) {
      z[subj, k] ~ std_normal();
    }
  }

  // ---- Likelihood: log(Y) ~ N(log y(t), 1/sqrt(prec.logy)) -------------------
  for (subj in 1:nsubj) {
    if (nsmpl[subj] > 0) {
      for (obs in 1:nsmpl[subj]) {
        for (k in 1:n_antigen_isos) {
          real mu_logy = log_two_phase(
            smpl_t[subj, obs],
            log(y0[subj, k]), log(y1[subj, k]), y1[subj, k],
            t1[subj, k], alpha[subj, k], shape[subj, k]);
          logy[subj, obs, k] ~ normal(mu_logy, inv_sqrt(prec_logy[k]));
        }
      }
    }
  }
}

generated quantities {
  // Reassemble the between-subject covariance matrices (for JAGS-vs-Stan checks).
  array[n_antigen_isos] matrix[n_params, n_params] Sigma_par;
  for (k in 1:n_antigen_isos) {
    Sigma_par[k] = multiply_lower_tri_self_transpose(
      diag_pre_multiply(sigma_par[k], L_corr[k]));
  }

  // Pointwise log-likelihood (per subject) for LOO / WAIC model comparison.
  vector[nsubj] log_lik;
  for (subj in 1:nsubj) {
    log_lik[subj] = 0;
    if (nsmpl[subj] > 0) {
      for (obs in 1:nsmpl[subj]) {
        for (k in 1:n_antigen_isos) {
          real mu_logy = log_two_phase(
            smpl_t[subj, obs],
            log(y0[subj, k]), log(y1[subj, k]), y1[subj, k],
            t1[subj, k], alpha[subj, k], shape[subj, k]);
          log_lik[subj] += normal_lpdf(logy[subj, obs, k] | mu_logy,
                                       inv_sqrt(prec_logy[k]));
        }
      }
    }
  }
}
