ver <- "v9na";

library(dplyr)
here::here() %>% fs::path("v9na") %>% setwd()

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
source(file.dat);
#smpl.t = time since symptom/fever onset for each participant, max 7 visits
#logy = log antibody response at each timepoint (max 7) for each of 7 biomarkers for each participant
#ntest is max number of biomarkers
#nsmpl = max number of samples per participant
#nsubj = number of study participants
#ndim = number of parameters to model(y0, y1, t1, alpha, shape)
#my.hyp, prec.hyp, omega and wishdf are all parameters to describe the shape of priors for (y0, y1, t1, alpha, shape) 


nchains <- 4;                # nr of MC chains to run simultaneously
nadapt  <- 1000;             # nr of iterations for adaptation
nburnin <- 1000;            # nr of iterations to use for burn-in
nmc     <- 1000;             # nr of samples in posterior chains
niter   <- 1000;            # nr of iterations for posterior sample
nthin   <- round(niter/nmc); # thinning needed to produce nmc from niter

pred.subj <- nsubj + 1;
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
