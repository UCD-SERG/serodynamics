sim_obs_times <- function(followup_interval, followup_variance, n_obs) {
  n_followup_obs <- n_obs - 1
  followup_range <- followup_interval + (-followup_variance:followup_variance)
  wait_times <-  
    sample(
      followup_range, 
      size = n_followup_obs,
      replace =  TRUE)
  followup_dates <- c(0,cumsum(wait_times))
  return(followup_dates)
}