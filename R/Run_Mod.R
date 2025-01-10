
### Function to RunJags
# Sam Schildhauer
# 1/10/25
#Creating a function to run stratified data
#Setting defaults -- 4 chains, 0 adapts, 0 burns, 100 nmc, 100 iter
Run.mod <- function(data, nchain=4, nadapt=0, nburn=0, nmc=100, niter=100, strat=NA) {
  
  ## Conditionally creating a stratification list to loop through
  if (is.na(strat)==F) {
  strat_list <<- unique(data[[strat]])
  }
  else {
  strat_list <<- "None"
  }
  
  ## Creating a shell to output results
  jags.out <- data.frame("Iteration"=NA, "Chain"=NA, "Parameter"=NA, "value"=NA, 
                         "Parameter_sub"=NA, "Subject"=NA, "Iso_type"=NA, "Stratification"=NA)
  
  ## Creating output list for jags.post
  jags.post.final <- list()
  
  #For loop for running stratifications
  for (i in strat_list) {
    #Creating if else statement for running the loop
    if (is.na(strat)==F) {
      dL_sub <- data %>%
        filter(data[[strat]]==i)
    }
    else {
      dL_sub <- data
    }
   
    #set seed for reproducibility
    set.seed(54321)
    #prepare data for modeline
    longdata <- prep_data(dL_sub)
    priors <- prep_priors(max_antigens = longdata$n_antigen_isos)
    
    #inputs for jags model
    nchains <- nchain;                # nr of MC chains to run simultaneously
    nadapt  <- nadapt;             # nr of iterations for adaptation
    nburnin <- nburn;            # nr of iterations to use for burn-in
    nmc     <- nmc;             # nr of samples in posterior chains
    niter   <- niter;            # nr of iterations for posterior sample
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
    #Assigning the raw jags output to a list. 
    # This will include a raw output for the jags.post for each stratification. 
    jags.post.final[[i]] <- jags.post  

    ## Cleaning the jags output -- much of this has to do with correctly classifying the [x,x] number 
    # included in the outputs
    #ggs works with mcmc objects
    jags_unpack <- ggs(jags.post[["mcmc"]])
    #extracting antigen-iso combinations to correctly number then by the order they are estimated by the program. 
    iso_dat <- data.frame(attributes(longdata)$antigens) 
    iso_dat <- iso_dat %>% mutate(Subnum = as.numeric(row.names(iso_dat)))
    ### Working with jags unpacked ggs outputs to clarify parameter and subject
    jags_unpack <- jags_unpack %>%
      mutate(Subnum = sub('.*,','',Parameter),
             Parameter_sub = sub('\\[.*','',Parameter),
             Subject = sub('\\,.*','',Parameter)) %>%
      mutate(Subnum = as.numeric(sub("\\].*",'',Subnum)),
             Subject = sub(".*\\[",'',Subject))
    # Merging isodat in to ensure we are classifying antigen_iso
    jags_unpack <- left_join(jags_unpack, iso_dat, by="Subnum") 
    jags_unpack <- jags_unpack %>%
      rename(c("Iso_type"="attributes.longdata..antigens"))%>%
      select(!c("Subnum"))
    # Setting subset for the "new person" -- setting it to the final sample
    np <- as.character(longdata$nsubj)
    jags_final <- jags_unpack %>%
      filter(Subject == np)
    ## Creating a label for the stratification, if there is one. If not, will add in "None".
    jags_final$Stratification <- i
    ## Creating output 
    jags.out <- data.frame(rbind(jags.out, jags_final))
    
  }
  ## Ensuring output does not have any NAs
  jags.out <- jags.out[complete.cases(jags.out),]
  ## Outputting the finalized jags output as a data frame with the jags output results for each stratification 
  # rbinded.
  jags.out <- list("curve_params"=jags.out,"jags.post"=jags.post.final)
  jags.out
} 

#Example code 
# Run.mod(data=Data set , nchain=4, nadapt=100, nburn=100, nmc=1000, niter=2000)
# Run.mod(data=Data set , nchain=4, nadapt=100, nburn=100, nmc=1000, niter=2000, strat=stratified variable)


