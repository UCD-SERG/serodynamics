#long data - CHOLERA
dL <-
  # read.csv("~/Library/CloudStorage/OneDrive-UniversityofCalifornia,Davis/Research/Cholera-longitudinal/data/cholera_data_compiled_050324.csv") %>%
  read_csv(here::here()  %>% fs::path("inst/extdata/cholera_data_compiled_050324.csv")) %>%
  group_by(index_id, antigen_iso) %>%                      # Group data by individual
  arrange(visit) %>%                          # Sort data by visit within each group
  mutate(visit_num = rank(visit, ties.method = "first")) %>%
  ungroup()

#set seed for reproducibility
set.seed(54321)
#subset data for checking
dL_sub <- dL %>%
  filter(index_id %in% sample(unique(index_id), 50))

#prepare data for modeline
# Construct the path to "prep_data.r" using here
prep_data_path <- here::here("R", "prep_data.r")
prep_priors_path <- here::here("R", "prep_priors.R")

# Source the file to load the prep_data function
source(prep_data_path)
source(prep_priors_path)

longdata <- prep_data(dL_sub)
priors <- prep_priors(max_antigens = longdata$n_antigen_isos)

#inputs for jags model
nchains <- 4;                # nr of MC chains to run simultaneously
nadapt  <- 100;             # nr of iterations for adaptation
nburnin <- 100;            # nr of iterations to use for burn-in
nmc     <- 100;             # nr of samples in posterior chains
niter   <- 1000;            # nr of iterations for posterior sample
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


file.mod <- here::here("inst", "extdata", "model.jags.r")

jags.post <- run.jags(model=file.mod,data=c(longdata, priors),
                      inits=initsfunction,method="parallel",
                      adapt=nadapt,burnin=nburnin,thin=nthin,sample=nmc,
                      n.chains=nchains,
                      monitor=tomonitor,summarise=FALSE);

jags.post2=jags.post

jags.post <- run.jags(model=file.mod,data=c(longdata, priors),
                      inits=initsfunction,method="parallel",
                      adapt=nadapt,burnin=nburnin,thin=nthin,sample=nmc,
                      n.chains=nchains,
                      monitor=tomonitor,summarise=FALSE);

all.equal(jags.post2,jags.post)


mcmc_list <- as.mcmc.list(jags.post)
mcmc_df <- ggs(mcmc_list)


wide_predpar_df <- mcmc_df %>%
  mutate(
    parameter = sub("^(\\w+)\\[.*", "\\1", Parameter),
    index_id = as.numeric(sub("^\\w+\\[(\\d+),.*", "\\1", Parameter)),
    antigen_iso = as.numeric(sub("^\\w+\\[\\d+,(\\d+).*", "\\1", Parameter))
  ) %>%
  mutate(
    index_id = factor(index_id, labels = attr(longdata, "ids")),
    antigen_iso = factor(antigen_iso, labels = attr(longdata, "antigens"))) %>%
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




# wide_predpar_df <- long_predpar_df %>%
#   mutate(
#     index_id = as.numeric(sub("^par\\[(\\d+),.*", "\\1", Variable)),
#     antigen_iso = as.numeric(sub("^par\\[\\d+,(\\d+),.*", "\\1", Variable)),
#     parameter = as.numeric(sub("^par\\[\\d+,\\d+,(\\d+)\\]", "\\1", Variable))
#   ) %>%
#   mutate(
#     index_id = factor(index_id, labels = c(unique(dL_sub$index_id), "newperson")),  
#     antigen_iso = factor(antigen_iso, labels = unique(dL_sub$antigen_iso)), 
#                          # parnum: use y0=1; y1=2; t1=3; alpha=4; shape=5
#                          # note to self - i dont like that these are not named anywhere....
#       parameter = factor(parameter, labels = c("y0", "y1", "t1", "alpha", "r"))) %>%
#       mutate(value = exp(value)) %>%
#       mutate(value = ifelse(parameter == "r", value+1, value)) %>%
#       ## only take the last subject (newperson)
#       filter(index_id == "newperson") %>%
#       select(-Variable) %>%
#       pivot_wider(names_from = "parameter", values_from="value") %>%
#       rowwise() %>%
#       mutate(y1 = y0+y1) %>%
#       droplevels() %>%
#       ungroup()






#Now plot longitudinal antibody decay 

curve_params <-
  wide_predpar_df

class(curve_params) =
  c("curve_params", class(curve_params))

antigen_isos = unique(curve_params$antigen_iso)

attr(curve_params, "antigen_isos") = antigen_isos

