################################################################################
## This is what Sam did

library(serodynamics)
library(serocalculator)
library(tidyverse)
library(runjags)
#library(coda)
library(ggmcmc)
library(dplyr)
library(tidyr)
library(stringr)

#model file
file.mod <- fs::path_package("serodynamics", "extdata/model.jags")

nepal_sees <- readr::read_csv(
  here::here() |>
    fs::path("/inst/extdata/SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv"))

# There are 188 subjects
dataset <- nepal_sees |>
  as_case_data(id_var = "person_id",
               biomarker_var = "antigen_iso",
               value_var = "result",
               time_in_days = "dayssincefeveronset")

# Subset typhi-->145 subjects
data_typhi<-dataset|>filter(bldculres=="typhi")

# Subset paratyphi-->43 subjects
data_paratyphi<-dataset|>filter(bldculres=="paratyphi")

# exclude one sample subject because I think they are not necessary to find residual plot<-????


# Apply run_mod function
nepal_sees_jags_post <- run_mod(
  data = dataset, # The data set input
  file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
  nchain = 2, # Number of mcmc chains to run
  nadapt = 100, # Number of adaptations to run
  nburn = 100, # Number of unrecorded samples before sampling begins
  nmc = 500,
  niter = 1000, # Number of iterations
  strat = "bldculres" # Stratification
) 

################################################################################
## Unpack jags.post output to get thousands of full posterior samples from MCMC per parameter

# get typhi samples
jags_unpack_typhi<-ggmcmc::ggs(nepal_sees_jags_post$jags.post$typhi$mcmc)

# get paratyphi samples
jags_unpack_paratyphi<-ggmcmc::ggs(nepal_sees_jags_post$jags.post$paratyphi$mcmc)

################################################################################
### Get median of each parameter distribution
## Start with paratyphi-->43 subjects
# Store each subject's 5 parameters


# Extract subject ID and antigen_iso from Parameter column
jags_processed <- jags_unpack_paratyphi %>%
  mutate(
    Parameter_clean = str_extract(Parameter, "^[a-zA-Z0-9]+"),  # Extract full parameter name (e.g., t1, y0, alpha)
    Subject = as.numeric(str_extract(Parameter, "(?<=\\[)\\d+")),  # Extract subject ID
    antigen_iso = as.numeric(str_extract(Parameter, "(?<=,)\\d+(?=\\])"))  # Extract antigen_iso (1 = IgA, 2 = IgG)
  ) %>%
  filter(!is.na(Parameter_clean))  # Remove any rows where extraction failed

# Problem: There are 44 subjects, how should I do?


# Compute median for each parameter per subject and antigen type
param_medians <- jags_processed %>%
  group_by(Subject, antigen_iso, Parameter_clean) %>%
  summarize(median_value = median(value), .groups = "drop")

# Reshape into wide format (one row per subject-antigen pair, with five parameters as columns)
param_medians_wide <- param_medians %>%
  pivot_wider(names_from = Parameter_clean, values_from = median_value)

# View the final structured dataframe
head(param_medians_wide)




## Typhi-->145 subjects