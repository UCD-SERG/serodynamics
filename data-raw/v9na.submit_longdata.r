ver <- "v9na";

devtools::load_all()
library(dplyr)
library(tidyverse)
here::here() %>% fs::path("data-raw") %>% setwd()


library(runjags)
# load.module("dic");

# file names
file.mod <- paste(ver,"model","jags",sep=".");
file.dat <- paste(ver,"data","r",sep=".");
file.ext <- paste(ver,"extract","r",sep=".");
file.res <- paste(ver,"resid","r",sep=".");
file.par <- paste(ver,"predpar","r",sep=".");
file.gra <- paste(ver,"predgraph","r",sep=".");
file.wds <- paste(ver,"wdist","r",sep=".");
file.cor <- paste(ver,"corr","r",sep=".");
file.scl <- paste(ver,"par-extract","r",sep=".");
file.age <- paste(ver,"age","r",sep=".");



#long data 
dL <- 
  read.csv("/Users/kristenaiemjoy/Dropbox/DataAnalysis/EntericFever/SEES Diagnostic Manuscript/Analysis/Source Data/elisa_clean_2023-02-23.csv") %>%
  filter(surgical != 1 | is.na(surgical))  %>%
  filter(Arm == "Prospective Cases" | Arm == "Retrospective Cases") %>%
  mutate(Hospitalized = ifelse((recloc == "Inpatient Department" | admithosp_seap == "Yes"), "Yes", "No")) %>% 
  mutate(antigen_iso = paste(elisa_antigen, "_", elisa_antbdy_iso, sep="")) %>%
  mutate(TimeInDays = ifelse(is.na(dayssincefeveronset), timesince0, dayssincefeveronset)) %>%
  mutate(TimePeriod = factor(TimePeriod, levels = c("Baseline","First visit", "28 days", "3 months","6 months", "12 months", "18 months", "24 months", "Last visit"))) %>%
  group_by(index_id, TimePeriod) %>% mutate(nVisits=n()) %>%
  ungroup() %>%
  select(index_id, Country, seapage, bldculres, Hospitalized, antigen_iso, result, TimePeriod,  postreinf, samplenum,  TimeInDays) %>%
  rename(age = seapage) %>%
  rename(visit = samplenum)  %>% 
  mutate(TimeInDays = ifelse(TimeInDays<0, 0, TimeInDays)) %>%
  mutate(visit = ifelse(is.na(visit) & TimePeriod == "Baseline", 1, visit)) %>%
  filter(antigen_iso!="YncE_IgG" & antigen_iso!= "CdtB_IgA" & antigen_iso != "CdtB_IgG") %>%
  droplevels()







longdata <- prep_data(dL)

nchains <- 4;                # nr of MC chains to run simultaneously
nadapt  <- 1000;             # nr of iterations for adaptation
nburnin <- 1000;            # nr of iterations to use for burn-in
nmc     <- 100;             # nr of samples in posterior chains
niter   <- 100;            # nr of iterations for posterior sample
nthin   <- round(niter/nmc); # thinning needed to produce nmc from niter

pred.subj <- longdata$nsubj + 1;
tomonitor <- c("par");

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

cat("<<< Extract parameter samples >>>\n");
source(file.ext);
cat("<<< Graph residuals >>>\n");
source(file.res);
cat("<<< Graph predicted parameter distributions >>>\n");
source(file.par);
cat("<<< Graph predicted responses >>>\n");
source(file.gra);
cat("<<< Graph rate distribution >>>\n");
source(file.wds);

# cat("<<< Define parameter sample for serocalculator >>>\n");
# source(file.scl);


## KA data extract paramters as an RDS file and not as an array
source("ka_mcmc.R")
