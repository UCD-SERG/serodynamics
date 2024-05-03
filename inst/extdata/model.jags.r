model {
 for (subj in  1:nsubj) {
  for (test in 1:ntest) { # `ntest` is the number of biomarkers being modeled
   # 
     # beta is called `mu` in Teunis et al Epidemics 2016; 
     # it is the antibody growth rate during the active infection
     # this expression corresponds to equation 17 in that paper
     beta[subj, test] <- log(y1[subj,test] / y0[subj,test]) / t1[subj,test]
     
    # `nsmpl` is the number of observations per `subject` 
   for(obs in 1:nsmpl[subj]) {
      
     # this is `log(y(t))` in the paper, before Gaussian noise is added
     mu.logy[subj,obs,test] <- ifelse(
        
        # `step(x)` returns 1 if x >= 0;
        # here we are determining which phase of infection we are in; 
        # active or recovery;
        # `smpl.t` is the time when the blood sample was collected, 
        # relative to estimated start of infection;
        # so we are determining whether the current observation is after `t1` 
        # the time when the active infection ended.
        step(t1[subj,test] - smpl.t[subj,obs]), 
        
        ## active infection period:
        # this is equation 15, case t <= t_1, but on a logarithmic scale
        log(y0[subj,test]) + (beta[subj,test] * smpl.t[subj,obs]),
        
        ## recovery period:
        # this is equation 15, case t > t_1
        1 / (1 - shape[subj,test]) *
           log(
              # this is `log{y_1^(1-r)}`; 
              # the exponent cancels out with the factor outside the log
              y1[subj, test]^(1 - shape[subj, test]) - 
                 
               # this is (1-r); not sure why switched from paper  
              (1 - shape[subj,test]) *
                
                  # (there's no missing y1^(r-1) term here; the math checks out)
                 
                 # alpha is `nu` in Teunis 2016; the "decay rate" parameter
                alpha[subj,test] *
                 
                 # this is `t - t_1`
                 (smpl.t[subj,obs] - t1[subj,test])))
     
     # we are fitting a loglinear model: log(Y) ~ N(mu, sigma^2)
     # this is the likelihood
     logy[subj,obs,test] ~ dnorm(mu.logy[subj,obs,test], prec.logy[test])
   }
     
   y0[subj,test]    <- exp(par[subj,test,1])
   y1[subj,test]    <- y0[subj,test] + exp(par[subj,test,2]) # par[,,2] must be log(y1-y0)
   t1[subj,test]    <- exp(par[subj,test,3])
   alpha[subj,test] <- exp(par[subj,test,4]) # `nu` in the paper
   shape[subj,test] <- exp(par[subj,test,5]) + 1 # `r` in the paper
   
   # `ndim` is the number of model parameters; y0, y1, t1, alpha (aka nu), and r
   # this is the prior distribution
   par[subj, test, 1:ndim] ~ dmnorm(mu.par[test,], prec.par[test,,])
  }
 }
   
 # hyperpriors   
 for(test in 1:ntest) {
    
  mu.par[test, 1:ndim] ~ dmnorm(mu.hyp[test,], prec.hyp[test,,])
  prec.par[test, 1:ndim, 1:ndim] ~ dwish(omega[test,,], wishdf[test])
  prec.logy[test] ~ dgamma(prec.logy.hyp[test,1], prec.logy.hyp[test,2])
 }
}
