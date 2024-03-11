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

# load data
library(dcm)

#long data 
dL <- readRDS("/cloud/project/data/sees_case_data_long_11012023.rds")

#filter out data after potential reinfections
##filter out all time points after reinfection
#janitor::clean_names()
dL_r <- dL %>%
  mutate(postreinf = ifelse(is.na(postreinf), 0, postreinf)) %>%
  filter(postreinf!=1) %>%
  select(-postreinf)

#make it wide
dR <- dL %>%
  select(-TimeInDays, -TimePeriod, -reinf_obs) %>%
  arrange(visit) %>%
  pivot_wider(names_from = antigen_iso, values_from = c(result), id_cols = c("index_id", "age", "visit", "Country", "bldculres", "Hospitalized")) %>%
  ungroup() %>%
  pivot_wider(names_from = visit, values_from = c(HlyE_IgA, HlyE_IgG, LPS_IgA, LPS_IgG, MP_IgA, MP_IgG, Vi_IgG),  id_cols = c("index_id", "age", "Country", "bldculres", "Hospitalized", 
  ), names_prefix = "visit")


dT <- dL %>% 
  select(index_id, visit, TimePeriod, TimeInDays) %>%
  distinct(., .keep_all = T) %>%
  pivot_wider(names_from = visit, values_from = c(TimeInDays), id_cols = c("index_id"), names_prefix = "TimeInDays_visit") %>%
  ungroup()


d.wide <- merge(dR, dT, by = c("index_id")) 



#d <- read_csv("/cloud/project/data/TypoidCaseData_github_09.30.21.csv")
longdata <- load_data(d.wide)

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
