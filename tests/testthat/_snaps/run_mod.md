# results are consistent with simulated data

    Code
      rlist::list.remove(attributes(results), c("row.names", "fitted_residuals",
        "population_params"))
    Output
      $names
      [1] "Iteration"      "Chain"          "Parameter"      "Iso_type"      
      [5] "Stratification" "Subject"        "value"         
      
      $class
      [1] "sr_model"   "tbl_df"     "tbl"        "data.frame"
      
      $nChains
      [1] 2
      
      $nParameters
      [1] 536
      
      $nIterations
      [1] 10
      
      $nBurnin
      [1] 200
      
      $nThin
      [1] 1
      
      $description
      [1] "jags_post[[\"mcmc\"]]"
      
      $priors
      $priors$mu_hyp_param
      [1]  1  7  1 -4 -1
      
      $priors$prec_hyp_param
      [1] 1e+00 1e-05 1e+00 1e-03 1e+00
      
      $priors$omega_param
      [1]  1 50  1 10  1
      
      $priors$wishdf_param
      [1] 20
      
      $priors$prec_logy_hyp_param
      [1] 4 1
      
      

# results are consistent with SEES data

    Code
      rlist::list.remove(attributes(results), c("row.names", "fitted_residuals",
        "population_params"))
    Output
      $names
      [1] "Iteration"      "Chain"          "Parameter"      "Iso_type"      
      [5] "Stratification" "Subject"        "value"         
      
      $class
      [1] "sr_model"   "tbl_df"     "tbl"        "data.frame"
      
      $nChains
      [1] 2
      
      $nParameters
      [1] 502
      
      $nIterations
      [1] 100
      
      $nBurnin
      [1] 20
      
      $nThin
      [1] 1
      
      $description
      [1] "jags_post[[\"mcmc\"]]"
      
      $priors
      $priors$mu_hyp_param
      [1]  1  7  1 -4 -1
      
      $priors$prec_hyp_param
      [1] 1e+00 1e-05 1e+00 1e-03 1e+00
      
      $priors$omega_param
      [1]  1 50  1 10  1
      
      $priors$wishdf_param
      [1] 20
      
      $priors$prec_logy_hyp_param
      [1] 4 1
      
      

# results are consistent with unstratified SEES data

    Code
      rlist::list.remove(attributes(results), c("row.names", "fitted_residuals",
        "population_params"))
    Output
      $names
      [1] "Iteration"      "Chain"          "Parameter"      "Iso_type"      
      [5] "Stratification" "Subject"        "value"         
      
      $class
      [1] "sr_model"   "tbl_df"     "tbl"        "data.frame"
      
      $nChains
      [1] 2
      
      $nParameters
      [1] 1952
      
      $nIterations
      [1] 100
      
      $nBurnin
      [1] 20
      
      $nThin
      [1] 1
      
      $description
      [1] "jags_post[[\"mcmc\"]]"
      
      $priors
      $priors$mu_hyp_param
      [1]  1  7  1 -4 -1
      
      $priors$prec_hyp_param
      [1] 1e+00 1e-05 1e+00 1e-03 1e+00
      
      $priors$omega_param
      [1]  1 50  1 10  1
      
      $priors$wishdf_param
      [1] 20
      
      $priors$prec_logy_hyp_param
      [1] 4 1
      
      

# results are consistent with unstratified SEES data with jags.post  included

    Code
      rlist::list.remove(attributes(results), c("row.names", "jags.post",
        "fitted_residuals", "population_params"))
    Output
      $names
      [1] "Iteration"      "Chain"          "Parameter"      "Iso_type"      
      [5] "Stratification" "Subject"        "value"         
      
      $class
      [1] "sr_model"   "tbl_df"     "tbl"        "data.frame"
      
      $nChains
      [1] 2
      
      $nParameters
      [1] 1952
      
      $nIterations
      [1] 100
      
      $nBurnin
      [1] 20
      
      $nThin
      [1] 1
      
      $description
      [1] "jags_post[[\"mcmc\"]]"
      
      $priors
      $priors$mu_hyp_param
      [1]  1  7  1 -4 -1
      
      $priors$prec_hyp_param
      [1] 1e+00 1e-05 1e+00 1e-03 1e+00
      
      $priors$omega_param
      [1]  1 50  1 10  1
      
      $priors$wishdf_param
      [1] 20
      
      $priors$prec_logy_hyp_param
      [1] 4 1
      
      

# results are consistent with unstratified SEES data with modified   priors

    Code
      rlist::list.remove(attributes(results), c("row.names", "fitted_residuals",
        "population_params"))
    Output
      $names
      [1] "Iteration"      "Chain"          "Parameter"      "Iso_type"      
      [5] "Stratification" "Subject"        "value"         
      
      $class
      [1] "sr_model"   "tbl_df"     "tbl"        "data.frame"
      
      $nChains
      [1] 2
      
      $nParameters
      [1] 1952
      
      $nIterations
      [1] 100
      
      $nBurnin
      [1] 20
      
      $nThin
      [1] 1
      
      $description
      [1] "jags_post[[\"mcmc\"]]"
      
      $priors
      $priors$mu_hyp_param
      [1]  1  4  1 -3 -1
      
      $priors$prec_hyp_param
      [1] 1e-02 1e-04 1e-02 1e-03 1e-02
      
      $priors$omega_param
      [1]  1 20  1 10  1
      
      $priors$wishdf_param
      [1] 10
      
      $priors$prec_logy_hyp_param
      [1] 3 1
      
      

