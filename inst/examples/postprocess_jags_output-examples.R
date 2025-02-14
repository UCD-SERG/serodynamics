set.seed(1)
raw_data <-
  serocalculator::typhoid_curves_nostrat_100 |>
  dplyr::filter(antigen_iso |> stringr::str_starts(pattern = "HlyE")) |> 
  sim_case_data(n = 5,
                antigen_isos = c("HlyE_IgA", "HlyE_IgG"))
prepped_data <- prep_data(raw_data)
priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)
nchains <- 2
# nr of MC chains to run simultaneously
nadapt <- 1000
# nr of iterations for adaptation
nburnin <- 100
# nr of iterations to use for burn-in
nmc <- 100
# nr of samples in posterior chains
niter <- 200
# nr of iterations for posterior sample
nthin <- round(niter / nmc)
# thinning needed to produce nmc from niter

tomonitor <- c("y0", "y1", "t1", "alpha", "shape")
# This handles the seed to reproduce the results
initsfunction <- function(chain) {
  stopifnot(chain %in% (1:4)) # max 4 chains allowed...
  .RNG.seed <- (1:4)[chain]
  .RNG.name <- c(
    "base::Wichmann-Hill", "base::Marsaglia-Multicarry",
    "base::Super-Duper", "base::Mersenne-Twister"
  )[chain]
  return(list(".RNG.seed" = .RNG.seed, ".RNG.name" = .RNG.name))
}

file.mod <- here::here("inst", "extdata", "model.jags.r")

set.seed(11325)
jags.post <- run.jags(
  model = file.mod,
  data = c(prepped_data, priors),
  inits = initsfunction,
  method = "parallel",
  adapt = nadapt,
  burnin = nburnin,
  thin = nthin,
  sample = nmc,
  n.chains = nchains,
  monitor = tomonitor,
  summarise = FALSE
)

curve_params <- jags.post |> postprocess_jags_output(
  ids = attr(prepped_data, "ids"),
  antigen_isos = attr(prepped_data, "antigens"))
