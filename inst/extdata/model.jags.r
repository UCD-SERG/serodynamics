model {
 for(subj in  1:nsubj){
  for(cur_antigen_iso in 1:n_antigen_isos) {
   beta[subj,cur_antigen_iso] <- log(y1[subj,cur_antigen_iso]/y0[subj,cur_antigen_iso])/t1[subj,cur_antigen_iso]
   for(obs in 1:nsmpl[subj]){
     mu.logy[subj,obs,cur_antigen_iso] <- ifelse(step(t1[subj,cur_antigen_iso]-smpl.t[subj,obs]),
       log(y0[subj,cur_antigen_iso])+(beta[subj,cur_antigen_iso]*smpl.t[subj,obs]),
       1/(1-shape[subj,cur_antigen_iso])*log(y1[subj,cur_antigen_iso]^(1-shape[subj,cur_antigen_iso])-
        (1-shape[subj,cur_antigen_iso])*alpha[subj,cur_antigen_iso]*(smpl.t[subj,obs]-t1[subj,cur_antigen_iso])))
     logy[subj,obs,cur_antigen_iso] ~ dnorm(mu.logy[subj,obs,cur_antigen_iso],prec.logy[cur_antigen_iso])
   }
   y0[subj,cur_antigen_iso]    <- exp(par[subj,cur_antigen_iso,1])
   y1[subj,cur_antigen_iso]    <- y0[subj,cur_antigen_iso]+exp(par[subj,cur_antigen_iso,2])
   t1[subj,cur_antigen_iso]    <- exp(par[subj,cur_antigen_iso,3])
   alpha[subj,cur_antigen_iso] <- exp(par[subj,cur_antigen_iso,4])
   shape[subj,cur_antigen_iso] <- exp(par[subj,cur_antigen_iso,5])+1
   par[subj,cur_antigen_iso,1:n_params] ~ dmnorm(mu.par[cur_antigen_iso,],prec.par[cur_antigen_iso,,])
  }
 }
 for(cur_antigen_iso in 1:n_antigen_isos) {
  mu.par[cur_antigen_iso,1:n_params] ~ dmnorm(mu.hyp[cur_antigen_iso,],prec.hyp[cur_antigen_iso,,])
  prec.par[cur_antigen_iso,1:n_params,1:n_params] ~ dwish(omega[cur_antigen_iso,,],wishdf[cur_antigen_iso])
  prec.logy[cur_antigen_iso] ~ dgamma(prec.logy.hyp[cur_antigen_iso,1],prec.logy.hyp[cur_antigen_iso,2])
 }
}
