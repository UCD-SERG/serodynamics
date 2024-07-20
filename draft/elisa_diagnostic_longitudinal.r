
devtools::load_all()
set.seed(54321)

#devtools::install_github("ucd-serg/serocalculator")
library(serocalculator)
library(tidyverse)
library(runjags)
library(coda)
library(ggmcmc)

date <- format(Sys.time(), "%m%d%Y")

#model file
#file.mod <- here::here()  %>% fs::path("inst/extdata/model.jags.r")
file.mod <- here::here()  %>% fs::path("inst/extdata/model.jags.r")

#long data - TYPHOID 
dL0 <-
# the raw data is prepared and shared by jessica Seidman
  read_csv(here::here()  %>% fs::path("inst/extdata/elisa_clean_2024-06-05.csv")) %>%
 filter(surgical != 1 | is.na(surgical))  %>%
  filter(Arm == "Prospective Cases" | Arm == "Retrospective Cases") %>%
  mutate(Hospitalized = ifelse((recloc == "Inpatient Department" | admithosp_seap == "Yes"), "Yes", "No")) %>%
  mutate(antigen_iso = paste(elisa_antigen, "_", elisa_antbdy_iso, sep="")) %>%
  mutate(timeindays = ifelse(is.na(dayssincefeveronset), timesince0, dayssincefeveronset)) %>%
  mutate(TimePeriod = factor(TimePeriod, levels = c("Baseline","First visit", "28 days", "3 months","6 months", "12 months", "18 months", "24 months", "Last visit"))) %>%
  group_by(index_id, TimePeriod) %>% mutate(nVisits=n()) %>%
  ungroup() %>%
  select(index_id, Country, seapage, ageScat, bldculres, Hospitalized, antigen_iso, result, TimePeriod,  postreinf, samplenum,  timeindays) %>%
  rename(age = seapage) %>%
  rename(visit_num = samplenum)  %>%
  mutate(timeindays = ifelse(timeindays<0, 0, timeindays)) %>%
  mutate(visit = ifelse(is.na(visit_num) & TimePeriod == "Baseline", 1, visit_num)) %>%
 # filter(!antigen_iso %in% c("YncE_IgG", "CdtB_IgA", "CdtB_IgG", "MP_IgA", "MP_IgG"))  %>%
  filter(antigen_iso %in% c("HlyE_IgA", "LPS_IgA")) %>%
  droplevels()



## filter IDs in the diagnostic case data set 
caseidlist <- read.csv("~/Library/CloudStorage/OneDrive-UniversityofCalifornia,Davis/Research/EF_ELISA_Diagnostics/Longitudinal/data/caseidlist.csv", sep="")


dL <- dL0 %>%
  filter(index_id %in% caseidlist$index_id) %>%
  filter(!is.na(visit_num)) 


## age strata
agelevels <- levels(as.factor(dL$ageScat))
level <- agelevels[5]
dL <- dL %>% filter(ageScat == level)

#overall
#level <- "overall"

#subset data for checking
# dL_sub <- dL %>%
#   filter(index_id %in% sample(unique(index_id), 20))


#prepare data for modeline
longdata <- prep_data(dL)
test <- as.data.frame(longdata$smpl.t) %>% filter(is.na(V1))


priors <- prep_priors(max_antigens = longdata$n_antigen_isos)

#inputs for jags model
nchains <- 4;                # nr of MC chains to run simultaneously
nadapt  <- 1000;             # nr of iterations for adaptation
nburnin <- 1000;            # nr of iterations to use for burn-in
nmc     <- 1000;             # nr of samples in posterior chains
niter   <- 10000;            # nr of iterations for posterior sample
nthin   <- round(niter/nmc); # thinning needed to produce nmc from niter

#pred.subj <- longdata$nsubj + 1;
#tomonitor <- c("par");
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
    index_id = factor(index_id, labels = c(unique(dL$index_id), "newperson")),
    antigen_iso = factor(antigen_iso, labels = unique(dL$antigen_iso))) %>%
 # mutate(value = exp(value)) %>%
 # mutate(value = ifelse(parameter == "r", value+1, value)) %>%
  ## only take the last subject (newperson)
  filter(index_id == "newperson") %>%
  select(-Parameter) %>%
  pivot_wider(names_from = "parameter", values_from="value") %>%
  rowwise() %>%
  #mutate(y1 = y0+y1) %>%
  droplevels() %>%
  ungroup() %>%
  rename(r = shape)




write_csv(wide_predpar_df, paste0("~/Library/CloudStorage/OneDrive-UniversityofCalifornia,Davis/Research/EF_ELISA_Diagnostics/Longitudinal/mcmc output/dmcmc_", level, "_", date, ".csv"))






#Now plot longitudinal antibody decay using serocalculator
# curve_params <-
#   wide_predpar_df
# 
#   class(curve_params) =
#   c("curve_params", class(curve_params))
# 
#   antigen_isos = unique(curve_params$antigen_iso)
# 
#   attr(curve_params, "antigen_isos") = antigen_isos
# 
# 
# plot.long <- autoplot(curve_params)



  
  
##Overall SeroCourse

  ab <- function(t,y0,y1,t1,alpha,shape) {
    beta <- bt(y0,y1,t1);
    yt <- 0;
    if(t <= t1) yt <- y0*exp(beta*t);
    if(t > t1) yt <- (y1^(1-shape)-(1-shape)*alpha*(t-t1))^(1/(1-shape));
    return(yt);
  }
  
  
  tx2 <- 10^seq(-1,3,0.025)
  
  bt <- function(y0,y1,t1) log(y1/y0)/t1
  
  
  dT <- data.frame(t=tx2) %>%
    mutate(ID = 1:n()) %>%
    pivot_wider(names_from = ID, values_from = t, names_prefix = "time") %>%
    slice(rep(1:n(), each = nrow(wide_predpar_df))) 
  
  
  serocourse.full <- cbind(wide_predpar_df, dT)  %>% pivot_longer(cols = starts_with("time"), values_to = "t") %>% select(-name)  %>%
    rowwise() %>%
    mutate(res = ab(t,y0,y1,t1,alpha,r)) 
  
  
  
  write_csv(serocourse.full, paste0("~/Library/CloudStorage/OneDrive-UniversityofCalifornia,Davis/Research/EF_ELISA_Diagnostics/Longitudinal/mcmc output/serocourse.full_", level, "_", date, ".csv"))
  
  
  serocourse.med <-  serocourse.full  %>% group_by(antigen_iso, t) %>%
    summarise(res.med  = quantile(res, 0.5),
              res.low  = quantile(res, 0.025),
              res.high = quantile(res, 0.975)) %>%
    pivot_longer(names_to = "quantile", cols = c("res.med","res.low","res.high"), names_prefix = "res.", values_to = "res") 
  
  write_csv(serocourse.med, paste0("~/Library/CloudStorage/OneDrive-UniversityofCalifornia,Davis/Research/EF_ELISA_Diagnostics/Longitudinal/mcmc output/serocourse.med_", level, "_", date, ".csv"))

  
