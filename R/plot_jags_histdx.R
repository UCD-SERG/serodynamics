

# -- Diagnostics using ggmcmc package
# -- Compiling into dataframe using ggs()
plot_jags_hist <- function(data=jags.post,iso=unique(visualize_jags_sub$Iso_type), param=unique(visualize_jags_sub$Parameter_sub)) {
  #Creating a ggs object, which is part of the jags package to create diagnostic plots
  visualize_jags <- ggs(data[["mcmc"]])
  
  # Creating columns to subset the outputs -- using regular expressions to do so from the output
  iso_dat <- data.frame(attributes(longdata)$antigens) 
  iso_dat <- iso_dat %>% mutate(Subnum = as.numeric(row.names(iso_dat)))
  visualize_jags <- visualize_jags %>%
    mutate(Subnum = sub('.*,','',Parameter),
           Parameter_sub = sub('\\[.*','',Parameter),
           Subject = sub('\\,.*','',Parameter)) %>%
    mutate(Subnum = as.numeric(sub("\\].*",'',Subnum)),
           Subject = sub(".*\\[",'',Subject))
  
  # Merging iso dat in to ensure we are plotting the name of the antigen correctly
  visualize_jags <- left_join(visualize_jags, iso_dat, by="Subnum") 
  # visualize_jags <- merge(visualize_jags, iso_dat, "Subnum", all=T) 
  visualize_jags <- visualize_jags %>%
    rename(c("Iso_type"="attributes.longdata..antigens"))%>%
    select(!c("Subnum"))
  # Setting subset for the "new person" -- setting it to the final sample
  np <- as.character(longdata$nsubj)
  visualize_jags_sub <- visualize_jags %>%
    filter(Subject == np)
  #Creating a label
  visualize_jags <- visualize_jags %>%
    mutate(Label = paste0(Iso_type,", ",Parameter_sub)) 
  
  #Creating loop to output diagnostics
  visualize_jags_plot <- visualize_jags_sub %>%
    filter(Iso_type %in% iso) %>%
    filter(Parameter_sub %in% param) %>%
    # Changing parameter name to reflect the input 
    mutate(Parameter=paste0("antigen=",Iso_type,", parameter=", Parameter_sub))
  ## Creating historgram plot
  histplot <- ggs_histogram(visualize_jags_plot)
  histplot
}

#Example call
# plot_jags_hist(jags.post,"hlya_IgA","y1")
plot_jags_hist(jags.post,c("hlya_IgG","hlya_IgA"),"y1")


