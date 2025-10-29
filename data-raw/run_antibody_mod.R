# run_antibody_cmdstanr.R

library(cmdstanr)
library(dplyr)
library(tidyr)
library(purrr)
library(Matrix)

cmdstanr::set_cmdstan_path("~/cmdstan") # adjust if installed elsewhere

# === Load your dataset ===
longdata <- readRDS("~/Documents/GitHub/serodynamics/inst/extdata/longdata_typh.rds")

# Identify dimensions
# nsubj <- length(unique(dat$subj))
# n_antigen_isos <- length(unique(dat$iso))

# For each subject, count # of samples
# nsmpl <- dat %>%
#   group_by(subj) %>%
#   summarise(n = n()) %>%
#   pull(n)

max_nsmpl <- max(longdata$nsmpl)

# Create matrices (pad with NA)
# make_matrix <- function(var) {
#   dat %>%
#     group_by(subj) %>%
#     summarise(vals = list(!!sym(var))) %>%
#     pull(vals) %>%
#     map(~c(.x, rep(NA, max_nsmpl - length(.x)))) %>%
#     do.call(cbind, .)
# }
# 
# smpl_t_mat <- make_matrix("smpl_t")
# logy_mat <- make_matrix("logy")

# Binary masks (1 = missing, 0 = observed)

smpl_t_miss_mask <- ifelse(is.na(long$smpl.t), 1, 0)

## This is already an array
logy_miss_mask <- ifelse(is.na(long$logy), 1, 0)

# Replace NA with 0 for data placeholders (Stan ignores them when mask==1)
smpl_t_obs <- ifelse(is.na(longdata$smpl.t), 0, longdata$smpl.t)
logy_obs <- ifelse(is.na(longdata$logy), 0, longdata$logy)

# Number of params
n_params <- 5

priorspec <- prep_priors(max_antigens = longdata$n_antigen_isos)

# mu_hyp <- matrix(0, long$n_antigen_isos, n_params)
# prec_hyp <- array(diag(1/10, n_params), dim = c(long$n_antigen_isos, n_params, n_params))
# omega <- array(diag(1, n_params), dim = c(n_antigen_isos, n_params, n_params))
# wishdf <- rep(n_params + 2, n_antigen_isos)
# prec_logy_hyp <- cbind(rep(2, n_antigen_isos), rep(1, n_antigen_isos))

## Creating the stan data list 
stan_data <- list(
  nsubj = longdata$nsubj,
  n_antigen_isos = longdata$n_antigen_isos,
  n_params = n_params,
  max_nsmpl = max_nsmpl,
  nsmpl = longdata$nsmpl,
  smpl_t_obs = smpl_t_obs,
  logy_obs = logy_obs,
  smpl_t_miss_mask = smpl_t_miss_mask,
  logy_miss_mask = logy_miss_mask,
  mu_hyp = priorspec$mu.hyp,
  prec_hyp = priorspec$prec.hyp,
  omega = priorspec$omega,
  wishdf = priorspec$wishdf,
  prec_logy_hyp = priorspec$prec.logy.hyp
)

# Assuming model file is saved as "antibody_model.stan"
## Compiling the stan model
mod <- cmdstan_model("~/Documents/GitHub/serodynamics/inst/extdata/model.stan")

fit <- mod$sample(
  data = stan_data,
  seed = 42,
  chains = 1,
  parallel_chains = 2,
  iter_warmup = 10,
  iter_sampling = 10,
  adapt_delta = 0.9,
  max_treedepth = 12,
  init = 0
)

# Assigning the raw jags output to a list.
# This object will include a raw output for the jags.post for each
# stratification and will only be included if specified. 
jags_post_final[[i]] <- jags_post

# Unpacking and cleaning MCMC output.
stan_unpack <- fit$summary()

# Working with jags unpacked ggs outputs to clarify parameter and subject
stan_unpack <- stan_unpack |>
  dplyr::mutate(
    Subnum = sub(".*,", "", .data$variable),
    Parameter_sub = sub("\\[.*", "", .data$variable),
    Subject = sub("\\,.*", "", .data$variable)
  ) |>
  dplyr::mutate(
    Subnum = as.numeric(sub("\\].*", "", .data$Subnum)),
    Subject = sub(".*\\[", "", .data$Subject)
  ) 
max_sub <- max(as.numeric(stan_unpack$Subject))
stan_newperson <- stan_unpack %>%
  filter(Subject == max(as.numeric(Subject)))



# Adding attributes
mod_atts <- attributes(jags_unpack)
# Only keeping necessary attributes
mod_atts <- mod_atts[4:8]

# extracting antigen-iso combinations to correctly number
# then by the order they are estimated by the program.
iso_dat <- data.frame(longdata$antigens)
iso_dat <- iso_dat |> dplyr::mutate(Subnum = as.numeric(row.names(iso_dat)))

# Merging isodat in to ensure we are classifying antigen_iso
jags_unpack <- dplyr::left_join(jags_unpack, iso_dat, by = "Subnum")
ids <- data.frame(attr(longdata, "ids")) |>
  mutate(Subject = as.character(dplyr::row_number()))
jags_unpack <- dplyr::left_join(jags_unpack, ids, by = "Subject")
jags_final <- jags_unpack |>
  dplyr::select(!c("Subnum", "Subject")) |>
  dplyr::rename(c("Iso_type" = "attributes.longdata..antigens",
                  "Subject" = "attr.longdata...ids.."))

# Replace the pattern with an empty string, effectively keeping only what's before it
result <- sub(pattern, "\\Q[\\E.*", my_string)

# Adding attributes
mod_atts <- attributes(jags_unpack)
# Only keeping necessary attributes
mod_atts <- mod_atts[4:8]

# extracting antigen-iso combinations to correctly number
# then by the order they are estimated by the program.
iso_dat <- data.frame(attributes(longdata)$antigens)
iso_dat <- iso_dat |> dplyr::mutate(Subnum = as.numeric(row.names(iso_dat)))
# Working with jags unpacked ggs outputs to clarify parameter and subject
jags_unpack <- jags_unpack |>
  dplyr::mutate(
    Subnum = sub(".*,", "", .data$Parameter),
    Parameter_sub = sub("\\[.*", "", .data$Parameter),
    Subject = sub("\\,.*", "", .data$Parameter)
  ) |>
  dplyr::mutate(
    Subnum = as.numeric(sub("\\].*", "", .data$Subnum)),
    Subject = sub(".*\\[", "", .data$Subject)
  )
# Merging isodat in to ensure we are classifying antigen_iso
jags_unpack <- dplyr::left_join(jags_unpack, iso_dat, by = "Subnum")
ids <- data.frame(attr(longdata, "ids")) |>
  mutate(Subject = as.character(dplyr::row_number()))
jags_unpack <- dplyr::left_join(jags_unpack, ids, by = "Subject")
jags_final <- jags_unpack |>
  dplyr::select(!c("Subnum", "Subject")) |>
  dplyr::rename(c("Iso_type" = "attributes.longdata..antigens",
                  "Subject" = "attr.longdata...ids.."))
# Creating a label for the stratification, if there is one.
# If not, will add in "None".
jags_final$Stratification <- i
## Creating output
jags_out <- data.frame(rbind(jags_out, jags_final))
}

