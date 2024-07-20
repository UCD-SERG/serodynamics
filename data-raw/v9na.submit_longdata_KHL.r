
## Code with my own comments



devtools::load_all()

devtools::install_github("ucd-serg/serocalculator")
library(serocalculator)
library(tidyverse)
library(runjags)
#library(coda)
library(ggmcmc)
library(here)

#model file
file.mod <- here::here()  %>% fs::path("inst/extdata/model.jags.r")
file.mod <- here::here()  %>% fs::path("inst/extdata/model.jags.2.r")


#long data - CHOLERA
 dL <- 
   read_csv(here::here()  %>% fs::path("inst/extdata/cholera_data_compiled_050324.csv")) %>%
   group_by(index_id, antigen_iso) %>%                      # Group data by individual
   arrange(visit) %>%                          # Sort data by visit within each group
   mutate(visit_num = rank(visit, ties.method = "first")) %>%
   ungroup()

 
#subset data for checking
 dL_sub <- dL %>%
   filter(index_id %in% sample(unique(index_id), 20))
 
 
 # Construct the path to "prep_data.r" using here
 prep_data_path <- here::here("R", "prep_data.r")
 prep_priors_path <- here::here("R", "prep_priors.R")
 
 # Source the file to load the prep_data function
 source(prep_data_path)
 source(prep_priors_path)
 
 #prepare data for modeline
 longdata <- prep_data(dL_sub)
 priors <- prep_priors(max_antigens = longdata$n_antigen_isos)
 
 
 #inputs for jags model
 nchains <- 4;                # nr of MC chains to run simultaneously
 nadapt  <- 100;             # nr of iterations for adaptation
 nburnin <- 100;            # nr of iterations to use for burn-in
 nmc     <- 100;             # nr of samples in posterior chains
 niter   <- 100;            # nr of iterations for posterior sample
 nthin   <- round(niter/nmc); # thinning needed to produce nmc from niter
 
 tomonitor <- c("y0", "y1", "t1", "alpha", "shape");
 
 
 #This handles the seed to reproduce the results 
 initsfunction <- function(chain){
   stopifnot(chain %in% (1:4)); # max 4 chains allowed...
   .RNG.seed <- (1:4)[chain];
   .RNG.name <- c("base::Wichmann-Hill","base::Marsaglia-Multicarry",
                  "base::Super-Duper","base::Mersenne-Twister")[chain];
   return(list(".RNG.seed"=.RNG.seed,".RNG.name"=.RNG.name));
 }
 
 
 
 jags.post <- run.jags(model=file.mod,data=c(longdata, priors),
                       inits=initsfunction,method="parallel",
                       adapt=nadapt,burnin=nburnin,thin=nthin,sample=nmc,
                       n.chains=nchains,
                       monitor=tomonitor,summarise=FALSE);
 
 
 mcmc_list <- as.mcmc.list(jags.post)
 
 mcmc_df <- ggs(mcmc_list)
 
 
 wide_predpar_df <- mcmc_df %>%
   mutate(
     parameter = sub("^(\\w+)\\[.*", "\\1", Parameter),
     index_id = as.numeric(sub("^\\w+\\[(\\d+),.*", "\\1", Parameter)),
     antigen_iso = as.numeric(sub("^\\w+\\[\\d+,(\\d+).*", "\\1", Parameter))
   ) %>%
   mutate(
     index_id = factor(index_id, labels = c(unique(dL_sub$index_id), "newperson")),
     antigen_iso = factor(antigen_iso, labels = unique(dL_sub$antigen_iso))) %>%
     filter(index_id == "newperson") %>%
     select(-Parameter) %>%
     pivot_wider(names_from = "parameter", values_from="value") %>%
     rowwise() %>%
     droplevels() %>%
     ungroup() %>%
     rename(r = shape)
 
 
 