devtools::load_all()

#devtools::install_github("ucd-serg/serocalculator")
library(serocalculator)
library(tidyverse)
library(runjags)
#library(coda)
library(ggmcmc)

#model file
#file.mod <- here::here()  %>% fs::path("inst/extdata/model.jags.r")
file.mod <- here::here()  %>% fs::path("inst/extdata/model.jags.2.r")

#long data - Shigella