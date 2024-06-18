
devtools::load_all()


library(tidyverse)
library(runjags)
library(coda)
library(ggmcmc)

#model file
file.mod <- here::here()  %>% fs::path("inst/extdata/model.jags.r")


#long data - TYPHOID 
# dL <-
# # the raw data is prepared and shared by jessica Seidman
#   read_csv(here::here()  %>% fs::path("inst/extdata/elisa_clean_2023-11-01.csv")) %>%
#  filter(surgical != 1 | is.na(surgical))  %>%
#   filter(Arm == "Prospective Cases" | Arm == "Retrospective Cases") %>%
#   mutate(Hospitalized = ifelse((recloc == "Inpatient Department" | admithosp_seap == "Yes"), "Yes", "No")) %>%
#   mutate(antigen_iso = paste(elisa_antigen, "_", elisa_antbdy_iso, sep="")) %>%
#   mutate(timeindays = ifelse(is.na(dayssincefeveronset), timesince0, dayssincefeveronset)) %>%
#   mutate(TimePeriod = factor(TimePeriod, levels = c("Baseline","First visit", "28 days", "3 months","6 months", "12 months", "18 months", "24 months", "Last visit"))) %>%
#   group_by(index_id, TimePeriod) %>% mutate(nVisits=n()) %>%
#   ungroup() %>%
#   select(index_id, Country, seapage, bldculres, Hospitalized, antigen_iso, result, TimePeriod,  postreinf, samplenum,  timeindays) %>%
#   rename(age = seapage) %>%
#   rename(visit_num = samplenum)  %>%
#   mutate(timeindays = ifelse(timeindays<0, 0, timeindays)) %>%
#   mutate(visit = ifelse(is.na(visit_num) & TimePeriod == "Baseline", 1, visit_num)) %>%
#   filter(!antigen_iso %in% c("YncE_IgG", "CdtB_IgA", "CdtB_IgG", "MP_IgA", "MP_IgG"))  %>%
#   droplevels()

#long data - CHOLERA
dL <- 
  #read.csv("~/Library/CloudStorage/OneDrive-UniversityofCalifornia,Davis/Research/Cholera-longitudinal/data/cholera_data_compiled_050324.csv") %>%
  read_csv(here::here()  %>% fs::path("inst/extdata/cholera_data_compiled_050324.csv")) %>%
  group_by(index_id, antigen_iso) %>%                      # Group data by individual
  arrange(visit) %>%                          # Sort data by visit within each group
  mutate(visit_num = rank(visit, ties.method = "first")) %>%
  ungroup()


#subset data for checking
# dL_sub <- dL %>%
#   filter(index_id %in% sample(unique(index_id), 20))

#Filtering data before running through program
dL_young <- dL %>% filter(age_years <= 5)
dL_old <- dL %>% filter(age_years > 5)
dL_vaccine <- dL %>% filter(cohort == "Vaccinee")
dL_case <- dL %>% filter(cohort == "Case")

dL_sub <- dL
#prepare data for modeline
longdata <- prep_data(dL_sub)


#inputs for jags model
nchains <- 4;                # nr of MC chains to run simultaneously
nadapt  <- 100;             # nr of iterations for adaptation
nburnin <- 100;            # nr of iterations to use for burn-in
nmc     <- 100;             # nr of samples in posterior chains
niter   <- 10000;            # nr of iterations for posterior sample
nthin   <- round(niter/nmc); # thinning needed to produce nmc from niter

#pred.subj <- longdata$nsubj + 1;
# tomonitor <- c("par");
tomonitor <- c("y0", "y1", "t1", "alpha", "shape");



#This handles the seed to reproduce the results 
initsfunction <- function(chain){
  stopifnot(chain %in% (1:4)); # max 4 chains allowed...
  .RNG.seed <- (1:4)[chain];
  .RNG.name <- c("base::Wichmann-Hill","base::Marsaglia-Multicarry",
                 "base::Super-Duper","base::Mersenne-Twister")[chain];
  return(list(".RNG.seed"=.RNG.seed,".RNG.name"=.RNG.name));
}


jags.post <- run.jags(model=file.mod,data=longdata,
                      inits=initsfunction,method="parallel",
                      adapt=nadapt,burnin=nburnin,thin=nthin,sample=nmc,
                      n.chains=nchains,
                      monitor=tomonitor,summarise=FALSE);

# Creating an output for each of the stratum
# jags.post_young <- jags.post
# jags.post_old <- jags.post
# jags.post_vaccine <- jags.post
# jags.post_case <- jags.post


### SS Diagonstic code 

# -- Running diagnostics using ggmcmc package
# -- Compiling into dataframe using ggs()
visualize_jags <- ggs(jags.post$mcmc)

plot_jags_hist <- function(x) {
  #Creating loop to output diagnostics
  params_list <- c(paste0("y0",x), paste0("y1",x), paste0("t1",x), paste0("alpha",x), paste0("shape",x))
  visualize_jags_sub <- visualize_jags%>%
    mutate(Parameter_char = as.character(Parameter)) %>%
    filter(Parameter_char %in% params_list)
  ## Creating historgrams
  ggs_histogram(visualize_jags_sub)
}
plot_jags_dens <- function(x) {
  #Creating loop to output diagnostics
  params_list <- c(paste0("y0",x), paste0("y1",x), paste0("t1",x), paste0("alpha",x), paste0("shape",x))
  visualize_jags_sub <- visualize_jags%>%
    mutate(Parameter_char = as.character(Parameter)) %>%
    filter(Parameter_char %in% params_list)
  ggs_density(visualize_jags_sub)
}
plot_jags_trace <- function(x) {
  #Creating loop to output diagnostics
  params_list <- c(paste0("y0",x), paste0("y1",x), paste0("t1",x), paste0("alpha",x), paste0("shape",x))
  visualize_jags_sub <- visualize_jags%>%
    mutate(Parameter_char = as.character(Parameter)) %>%
    filter(Parameter_char %in% params_list)
  ## Traceplots
  ggs_traceplot(visualize_jags_sub)
}
summ_jags <- function(x) {
  #Creating loop to output diagnostics
  params_list <- c(paste0("y0",x), paste0("y1",x), paste0("t1",x), paste0("alpha",x), paste0("shape",x))
  visualize_jags_sub <- visualize_jags%>%
    mutate(Parameter_char = as.character(Parameter)) %>%
    filter(Parameter_char %in% params_list)
  ### Short summary 
  ci(visualize_jags_sub)[,c(1:6)]
}

plot_jags_trace("[3,3]")
plot_jags_dens("[3,3]")
plot_jags_hist("[3,3]")
summ_jags("[3,3]")

####### SS Diagonstic code 

# Look into these lines. Want to be able to work with output in ggplot. 
# ggmcmc package 
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






#Now plot longitudinal antibody decay 
# devtools::install_github("ucd-serg/serocalculator")
library(serocalculator)



curve_params <- 
  wide_predpar_df
  
  class(curve_params) =
  c("curve_params", class(curve_params))
  
  antigen_isos = unique(curve_params$antigen_iso)
  
  attr(curve_params, "antigen_isos") = antigen_isos


autoplot(curve_params)
# curve_params_young <- curve_params
# curve_params_old <- curve_params
# curve_params_vaccine <- curve_params
curve_params_case <- curve_params

# Putting all params together
curve_params_young$Type <- "Young"
curve_params_old$Type <- "Old"
curve_params_age <- rbind(curve_params_young, curve_params_old)

curve_params_vaccine$Type <- "Vaccine"
curve_params_case$Type <- "Case"
curve_params_vax <- rbind(curve_params_vaccine, curve_params_case)


# Plotting curves
ggplot(curve_params_age, aes(x=))

#Plotting curve parameters 
# At Y =0 
ggplot(curve_params_age, aes(x=y0, group=Type, color=Type)) +
  geom_density()+
  facet_wrap(~antigen_iso)
ggplot(curve_params_vax, aes(x=y0, group=Type, color=Type)) +
  geom_density()+
  facet_wrap(~antigen_iso)


# Plotting curves

# At Y=1
ggplot(curve_params_age, aes(x=y1, group=Type, color=Type)) +
  geom_density() +
  facet_wrap(~antigen_iso) +
  scale_x_log10()
ggplot(curve_params_vax, aes(x=y1, group=Type, color=Type)) +
  geom_density()+
  facet_wrap(~antigen_iso) +
  scale_x_log10()

# At t=1
ggplot(curve_params_age, aes(x=t1, group=Type, color=Type)) +
  geom_density()+
  facet_wrap(~antigen_iso)+
  scale_x_log10()
ggplot(curve_params_vax, aes(x=t1, group=Type, color=Type)) +
  geom_density()+
  facet_wrap(~antigen_iso)+
  scale_x_log10()

# Alpha
ggplot(curve_params, aes(x=alpha)) +
  geom_density()

