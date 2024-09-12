# Load necessary packages
library(tidyverse)
library(here)
library(fs)
library(runjags)
library(testthat)

# Load the data
dL <- read_csv(here::here() %>% fs::path("inst/extdata/cholera_data_compiled_050324.csv")) %>%
  group_by(index_id, antigen_iso) %>%
  arrange(visit) %>%
  mutate(visit_num = rank(visit, ties.method = "first")) %>%
  ungroup()

# Set seed for reproducibility
set.seed(54321)

# Subset the data
dL_sub <- dL %>%
  filter(index_id %in% sample(unique(index_id), 50))

# Load the prep_data and prep_priors functions
prep_data_path <- here::here("R", "prep_data.r")
prep_priors_path <- here::here("R", "prep_priors.R")
source(prep_data_path)
source(prep_priors_path)

# Prepare data for the model
longdata <- prep_data(dL_sub)
priors <- prep_priors(max_antigens = longdata$n_antigen_isos)

# Define inputs for JAGS model
nchains <- 4
nadapt  <- 100
nburnin <- 100
nmc     <- 100
niter   <- 1000
nthin   <- round(niter / nmc)
tomonitor <- c("y0", "y1", "t1", "alpha", "shape")

# Initialize function to set up the seed for reproducibility
initsfunction <- function(chain) {
  stopifnot(chain %in% 1:4) # Max 4 chains allowed
  .RNG.seed <- (1:4)[chain]
  .RNG.name <- c("base::Wichmann-Hill", "base::Marsaglia-Multicarry",
                 "base::Super-Duper", "base::Mersenne-Twister")[chain]
  return(list(".RNG.seed" = .RNG.seed, ".RNG.name" = .RNG.name))
}

# JAGS model file path
file.mod <- here::here("inst", "extdata", "model.jags.r")

# Test using testthat
test_that("JAGS model gives consistent results with the same RNG inputs", {
  # First JAGS run
  jags.post <- run.jags(model = file.mod, 
                        data = c(longdata, priors), 
                        inits = initsfunction, 
                        method = "parallel", 
                        adapt = nadapt, 
                        burnin = nburnin, 
                        thin = nthin, 
                        sample = nmc, 
                        n.chains = nchains, 
                        monitor = tomonitor, 
                        summarise = FALSE)
  
  # Store the result of the first run
  jags.post2 <- jags.post
  
  # Second JAGS run with the same settings
  jags.post <- run.jags(model = file.mod, 
                        data = c(longdata, priors), 
                        inits = initsfunction, 
                        method = "parallel", 
                        adapt = nadapt, 
                        burnin = nburnin, 
                        thin = nthin, 
                        sample = nmc, 
                        n.chains = nchains, 
                        monitor = tomonitor, 
                        summarise = FALSE)
  
  # Test if the results are the same
  expect_equal(jags.post2, jags.post)
})


