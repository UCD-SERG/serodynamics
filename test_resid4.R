################################################################################
## Simple version of test_resid3.R file

library(serodynamics)
library(serocalculator)
library(tidyverse)
library(runjags)
library(ggmcmc)
library(dplyr)
library(tidyr)
library(stringr)

#model file
file.mod <- fs::path_package("serodynamics", "extdata/model.jags")

nepal_sees <- readr::read_csv(
  here::here() |>
    fs::path("/inst/extdata/SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv"))

# There are 188 subjects
dataset <- nepal_sees |>
  as_case_data(id_var = "person_id",
               biomarker_var = "antigen_iso",
               value_var = "result",
               time_in_days = "dayssincefeveronset")

# Extract specific observation for visit_num is 5
subset_data <- dataset %>% filter(visit_num == 5)

# Extract only the unique (id, antigen_iso) pairs from subset_data
id_antigen_pairs <- subset_data %>% select(id, antigen_iso) %>% distinct()

# Filter the original dataset for those id and antigen_iso combinations
filtered_dataset <- dataset %>%
  semi_join(id_antigen_pairs, by = c("id", "antigen_iso")) %>%
  filter(visit_num >= 1 & visit_num <= 5)  # Ensure visit_num is within 1 to 5

###############################################################################
## There are 3 subjects (sees_npl_128, sees_npl_131, sees_npl_133) that have 5 visit numbers.
## I will extract sees_npl_128 only and work on it.
###############################################################################

dat<-filtered_dataset%>%
  filter(id=="sees_npl_128")

# Apply run_mod function
nepal_sees_jags_post <- run_mod(
  data = dat, # The data set input
  file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
  nchain = 2, # Number of mcmc chains to run
  nadapt = 100, # Number of adaptations to run
  nburn = 100, # Number of unrecorded samples before sampling begins
  nmc = 500,
  niter = 1000, # Number of iterations
  strat = "bldculres" # Stratification
) 


################################################################################
## Unpack jags.post output to get thousands of full posterior samples from MCMC per parameter
jags_unpack_128<-ggmcmc::ggs(nepal_sees_jags_post$jags.post$typhi$mcmc)

################################################################################
### Get median of each parameter distribution

# Extract subject ID and antigen_iso from Parameter column
jags_processed_128 <- jags_unpack_128 %>%
  mutate(
    Parameter_clean = str_extract(Parameter, "^[a-zA-Z0-9]+"),  # Extract full parameter name (e.g., t1, y0, alpha)
    Subject = as.numeric(str_extract(Parameter, "(?<=\\[)\\d+")),  # Extract subject ID
    antigen_iso = as.numeric(str_extract(Parameter, "(?<=,)\\d+(?=\\])"))  # Extract antigen_iso (1 = IgA, 2 = IgG)
  ) %>%
  filter(!is.na(Parameter_clean))  # Remove any rows where extraction failed

# Problem: There are 2subjects!
# Create function to remove last subject observations
remove_extra_subject <- function(data, subject_col = "Subject") {
  max_subject <- max(data[[subject_col]])  # Identify the highest Subject number
  filtered_data <- data %>% filter(.data[[subject_col]] != max_subject)  # Remove it
  return(filtered_data)
}

# Apply the function to your dataset
jags_processed_128_fixed <- remove_extra_subject(jags_processed_128)


# Compute median for each parameter per subject and antigen type
param_medians_128 <- jags_processed_128_fixed %>%
  group_by(Subject, antigen_iso, Parameter_clean) %>%
  summarize(median_value = median(value), .groups = "drop")

# Reshape into wide format (one row per subject-antigen pair, with five parameters as columns)
param_medians_wide_128 <- param_medians_128 %>%
  pivot_wider(names_from = Parameter_clean, values_from = median_value)

# View the final structured dataframe
head(param_medians_wide_128)

################################################################################
## Edit graph.curve.params() function

graph.curve.params.subject <- function(
    curve_params,
    antigen_isos = unique(curve_params$antigen_iso),
    verbose = FALSE,
    show_all_curves = TRUE,  # Show individual subject curves
    alpha_samples = 0.3  # Adjust transparency
) {
  if (verbose) {
    message(
      "Graphing subject-specific curves for antigen isotypes: ",
      paste(antigen_isos, collapse = ", ")
    )
  }
  
  curve_params <- curve_params %>%
    filter(antigen_iso %in% antigen_isos)
  
  tx2 <- seq(0, 1200, by = 5)  # Regularly spaced time points instead of log scale
  
  # Define antibody decay function
  ab <- function(t, y0, y1, t1, alpha, shape) {
    beta <- log(y1 / y0) / t1
    yt <- ifelse(t <= t1,
                 y0 * exp(beta * t), 
                 (y1^(1 - shape) - (1 - shape) * alpha * (t - t1))^(1 / (1 - shape)))
    return(yt)
  }
  
  # Create time points for prediction
  dT <- data.frame(t = tx2) %>%
    mutate(ID = row_number()) %>%
    pivot_wider(names_from = ID, values_from = t, names_prefix = "time") %>%
    slice(rep(1:n(), each = nrow(curve_params)))
  
  # Generate predicted antibody levels for each subject
  serocourse_all <- cbind(curve_params, dT) %>%
    pivot_longer(cols = starts_with("time"), values_to = "t") %>%
    select(-name) %>%
    rowwise() %>%
    mutate(res = ab(t, y0, y1, t1, alpha, shape)) %>%
    ungroup()
  
  # Plot individual subject curves
  plot1 <- ggplot() +
    aes(x = t, y = res, group = Subject, color = factor(Subject)) +
    facet_wrap(~ antigen_iso, ncol = 2) +
    geom_line(data = serocourse_all, alpha = alpha_samples) +  # Subject-specific curves
    theme_minimal() +
    labs(x = "Days since fever onset", y = "ELISA units", color = "Subject") +
    theme(legend.position = "none")  # Remove legend if too many subjects
  
  return(plot1)
}
################################################################################
## Using this 5 median parameters to plot predicted curve(param_medians_wide_128)
plot_paratyphi_curves <- graph.curve.params.subject(
  curve_params = param_medians_wide_128,
  antigen_isos = unique(param_medians_wide_128$antigen_iso),
  verbose = TRUE,
  show_all_curves = TRUE,  # Show individual subject curves
  alpha_samples = 0.3  # Transparency of individual curves
)

# Display the plot
print(plot_paratyphi_curves)

################################################################################
### Based on predicted curve, get predicted_result for each days since fever onset
## Create a Mapping Table and Update Values

# Step 1: Create mapping for id 
unique_ids <- unique(dat$id)  # Get unique subject IDs
subject_mapping <- data.frame(
  id = unique_ids,
  Subject = seq_along(unique_ids)  # Assign numbers 1 to 43
)

# Step 2: Convert antigen_iso (1 → HlyE_IgA, 2 → HlyE_IgG)
param_medians_wide_128 <- param_medians_wide_128 %>%
  mutate(antigen_iso = case_when(
    antigen_iso == 1 ~ "HlyE_IgA",
    antigen_iso == 2 ~ "HlyE_IgG"
  ))

# Step 3: Update the original dataset to match subjects
# Convert antigen_iso to character in both datasets for consistent join
dat_update <- 
  dat|>
  mutate(antigen_iso = case_when(
    antigen_iso == 1 ~ "HlyE_IgA",
    antigen_iso == 2 ~ "HlyE_IgG",
    TRUE ~ as.character(antigen_iso)  # Ensure all are character type
  ))|>
  left_join(subject_mapping,by=c("id"))

# Ensure antigen_iso in param_medians_wide_128 is also character
param_medians_wide_128 <- param_medians_wide_128 %>%
  mutate(antigen_iso = as.character(antigen_iso))

# Step 4: Define antibody decay function
ab <- function(t, y0, y1, t1, alpha, shape) {
  beta <- log(y1 / y0) / t1
  yt <- ifelse(t <= t1,
               y0 * exp(beta * t), 
               (y1^(1 - shape) - (1 - shape) * alpha * (t - t1))^(1 / (1 - shape)))
  return(yt)
}

# Step 5: Join with modeled parameters and compute predicted_result
dat_update <- dat_update %>%
  left_join(param_medians_wide_128, by = c("Subject", "antigen_iso")) %>%
  rowwise() %>%
  mutate(predicted_result = ab(dayssincefeveronset, y0, y1, t1, alpha, shape)) %>%
  ungroup()

# View the updated dataset
head(dat_update)

################################################################################
### Compute residuals and re-organize data

dat_resid <- 
  dat_update |>
  mutate(
    residual = result - predicted_result,  # Regular residual
    abs_residual = abs(result - predicted_result)  # Absolute residual
  )|>
  select(Country,id,sample_id,bldculres,antigen_iso,studyvisit,dayssincefeveronset,
         visit_num,result,predicted_result,residual,abs_residual)

# View the updated dataset
head(dat_resid)

################################################################################
### From dat_resid we will use abs_residual to get 5parameters

## Cleaning dat_resid so we can run in run_mod function
dat_resid_modified <- dat_resid %>%
  select(-result, -predicted_result, -residual) %>%  # Remove unwanted columns
  rename(result = abs_residual)%>%  # Rename abs_residual to result
  select(Country,id,sample_id,bldculres,antigen_iso,studyvisit,
         dayssincefeveronset,result,visit_num)

## Restore attributes
restore_attributes <- function(dat_target, dat_reference) {
  # List of attributes to restore
  attrs_to_restore <- c("id_var", "biomarker_var", "timeindays", "value_var")
  
  # Restore each attribute from dat_reference if it exists
  for (attr_name in attrs_to_restore) {
    if (!is.null(attributes(dat_reference)[[attr_name]])) {
      attributes(dat_target)[[attr_name]] <- attributes(dat_reference)[[attr_name]]
    }
  }
  
  # Restore class attributes to match the reference dataset
  class(dat_target) <- class(dat_reference)
  
  # Return the modified dataset
  return(dat_target)
}

# Apply the function
dat_resid_modified <- restore_attributes(dat_resid_modified, dat)

# Check if attributes are restored
attributes(dat_resid_modified)

# Apply run_mod function
nepal_sees_jags_post2 <- run_mod(
  data = dat_resid_modified, # The data set input
  file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
  nchain = 2, # Number of mcmc chains to run
  nadapt = 100, # Number of adaptations to run
  nburn = 100, # Number of unrecorded samples before sampling begins
  nmc = 500,
  niter = 1000, # Number of iterations
  strat = "bldculres" # Stratification
) 

################################################################################
## Unpack jags.post output to get thousands of full posterior samples from MCMC per parameter

jags_unpack_128_2<-ggmcmc::ggs(nepal_sees_jags_post2$jags.post$typhi$mcmc)
################################################################################
### Get median of each parameter distribution

# Extract subject ID and antigen_iso from Parameter column
jags_processed_128_2 <- jags_unpack_128_2 %>%
  mutate(
    Parameter_clean = str_extract(Parameter, "^[a-zA-Z0-9]+"),  # Extract full parameter name (e.g., t1, y0, alpha)
    Subject = as.numeric(str_extract(Parameter, "(?<=\\[)\\d+")),  # Extract subject ID
    antigen_iso = as.numeric(str_extract(Parameter, "(?<=,)\\d+(?=\\])"))  # Extract antigen_iso (1 = IgA, 2 = IgG)
  ) %>%
  filter(!is.na(Parameter_clean))  # Remove any rows where extraction failed

# Apply the function to your dataset
jags_processed_128_2_fixed <- remove_extra_subject(jags_processed_128_2)


# Compute median for each parameter per subject and antigen type
param_medians_128_2 <- jags_processed_128_2_fixed %>%
  group_by(Subject, antigen_iso, Parameter_clean) %>%
  summarize(median_value = median(value), .groups = "drop")

# Reshape into wide format (one row per subject-antigen pair, with five parameters as columns)
param_medians_wide_128_2 <- param_medians_128_2 %>%
  pivot_wider(names_from = Parameter_clean, values_from = median_value)

# View the final structured dataframe
head(param_medians_wide_128_2)

################################################################################
## Using this 5 median parameters to plot predicted curve(param_medians_wide_128)
plot_paratyphi_curves2 <- graph.curve.params.subject(
  curve_params = param_medians_wide_128_2,
  antigen_isos = unique(param_medians_wide_128_2$antigen_iso),
  verbose = TRUE,
  show_all_curves = TRUE,  # Show individual subject curves
  alpha_samples = 0.3  # Transparency of individual curves
)

# Display the plot
print(plot_paratyphi_curves2)
