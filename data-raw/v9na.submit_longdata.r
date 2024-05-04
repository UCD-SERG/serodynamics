
devtools::load_all()

library(dplyr)
library(tidyverse)
library(runjags)


#model file
file.mod <- here::here()  %>% fs::path("inst/extdata/model.jags.r")


#long data - TYPHOID 
dL <-
  #the raw data is prepared and shared by jessica Seidman
  read_csv(here::here()  %>% fs::path("inst/extdata/elisa_clean_2023-11-01.csv")) %>%
 filter(surgical != 1 | is.na(surgical))  %>%
  filter(Arm == "Prospective Cases" | Arm == "Retrospective Cases") %>%
  mutate(Hospitalized = ifelse((recloc == "Inpatient Department" | admithosp_seap == "Yes"), "Yes", "No")) %>%
  mutate(antigen_iso = paste(elisa_antigen, "_", elisa_antbdy_iso, sep="")) %>%
  mutate(timeindays = ifelse(is.na(dayssincefeveronset), timesince0, dayssincefeveronset)) %>%
  mutate(TimePeriod = factor(TimePeriod, levels = c("Baseline","First visit", "28 days", "3 months","6 months", "12 months", "18 months", "24 months", "Last visit"))) %>%
  group_by(index_id, TimePeriod) %>% mutate(nVisits=n()) %>%
  ungroup() %>%
  select(index_id, Country, seapage, bldculres, Hospitalized, antigen_iso, result, TimePeriod,  postreinf, samplenum,  timeindays) %>%
  rename(age = seapage) %>%
  rename(visit_num = samplenum)  %>%
  mutate(timeindays = ifelse(timeindays<0, 0, timeindays)) %>%
  mutate(visit = ifelse(is.na(visit_num) & TimePeriod == "Baseline", 1, visit_num)) %>%
  filter(!antigen_iso %in% c("YncE_IgG", "CdtB_IgA", "CdtB_IgG", "MP_IgA", "MP_IgG"))  %>%
  droplevels()

#long data - CHOLERA
# dL <- read.csv("~/Library/CloudStorage/OneDrive-UniversityofCalifornia,Davis/Research/Cholera-longitudinal/data/cholera_data_compiled_050324.csv") %>%
#   group_by(index_id, antigen_iso) %>%                      # Group data by individual
#   arrange(visit) %>%                          # Sort data by visit within each group
#   mutate(visit_num = rank(visit, ties.method = "first")) %>%
#   ungroup() 


#subset data for checking
dL_sub <- dL %>%
  filter(index_id %in% sample(unique(index_id), 20))


#prepare data for modeline
longdata <- prep_data(dL_sub)


#inputs for jags model
nchains <- 4;                # nr of MC chains to run simultaneously
nadapt  <- 100;             # nr of iterations for adaptation
nburnin <- 100;            # nr of iterations to use for burn-in
nmc     <- 100;             # nr of samples in posterior chains
niter   <- 100;            # nr of iterations for posterior sample
nthin   <- round(niter/nmc); # thinning needed to produce nmc from niter

#pred.subj <- longdata$nsubj + 1;
tomonitor <- c("par");

initsfunction <- function(chain){
  stopifnot(chain %in% (1:4)); # max 4 chains allowed...
  .RNG.seed <- (1:4)[chain];
  .RNG.name <- c("base::Wichmann-Hill","base::Marsaglia-Multicarry",
                 "base::Super-Duper","base::Mersenne-Twister")[chain];
  return(list(".RNG.seed"=.RNG.seed,".RNG.name"=.RNG.name));
}



jags.post <- run.jags(
  model = file.mod, 
  data = longdata, 
  inits = initsfunction, 
  method = "parallel", 
  adapt = nadapt, 
  burnin = nburnin, 
  thin = nthin, 
  sample = nmc, 
  n.chains = nchains, 
  monitor = c("y0", "y1", "t1", "alpha", "shape"), 
  summarise = FALSE)



mcmc_list <- as.mcmc.list(jags.post)
mcmc_matrix <- as.matrix(mcmc_list)
mcmc_df <- as.data.frame(mcmc_matrix)


# Adding iteration numbers
iterations <- rep(1:nrow(mcmc_matrix), each = ncol(mcmc_matrix))

# Reshape the data frame
long_predpar_df <- pivot_longer(mcmc_df, cols = everything(), names_to = "Variable", values_to = "value")
long_predpar_df$iter <- iterations


wide_predpar_df <- long_predpar_df %>%
  mutate(
    index_id = as.numeric(sub("^par\\[(\\d+),.*", "\\1", Variable)),
    antigen_iso = as.numeric(sub("^par\\[\\d+,(\\d+),.*", "\\1", Variable)),
    parameter = as.numeric(sub("^par\\[\\d+,\\d+,(\\d+)\\]", "\\1", Variable))
  ) %>%
  mutate(
    index_id = factor(index_id, labels = c(unique(dL_sub$index_id), "newperson")),  
    antigen_iso = factor(antigen_iso, labels = unique(dL_sub$antigen_iso)), 
                         # parnum: use y0=1; y1=2; t1=3; alpha=4; shape=5
                         # note to self - i dont like that these are not named anywhere....
      parameter = factor(parameter, labels = c("y0", "y1", "t1", "alpha", "r"))) %>%
      mutate(value = exp(value)) %>%
      mutate(value = ifelse(parameter == "r", value+1, value)) %>%
      ## only take the last subject (newperson)
      filter(index_id == "newperson") %>%
      select(-Variable) %>%
      pivot_wider(names_from = "parameter", values_from="value") %>%
      rowwise() %>%
      mutate(y1 = y0+y1) %>%
      droplevels() %>%
      ungroup()











