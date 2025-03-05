################################################################################
## This is what Sam did

library(serodynamics)
library(serocalculator)
library(tidyverse)
library(runjags)
#library(coda)
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

# Subset typhi-->145 subjects
data_typhi<-dataset|>filter(bldculres=="typhi")

# Subset paratyphi-->43 subjects
data_paratyphi<-dataset|>filter(bldculres=="paratyphi")

# exclude one sample subject because I think they are not necessary to find residual plot<-????


# Apply run_mod function
nepal_sees_jags_post <- run_mod(
  data = dataset, # The data set input
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

# get typhi samples
jags_unpack_typhi<-ggmcmc::ggs(nepal_sees_jags_post$jags.post$typhi$mcmc)

# get paratyphi samples
jags_unpack_paratyphi<-ggmcmc::ggs(nepal_sees_jags_post$jags.post$paratyphi$mcmc)

################################################################################
### Get median of each parameter distribution
## Start with paratyphi-->43 subjects
# Store each subject's 5 parameters


# Extract subject ID and antigen_iso from Parameter column
jags_processed_paratyphi <- jags_unpack_paratyphi %>%
  mutate(
    Parameter_clean = str_extract(Parameter, "^[a-zA-Z0-9]+"),  # Extract full parameter name (e.g., t1, y0, alpha)
    Subject = as.numeric(str_extract(Parameter, "(?<=\\[)\\d+")),  # Extract subject ID
    antigen_iso = as.numeric(str_extract(Parameter, "(?<=,)\\d+(?=\\])"))  # Extract antigen_iso (1 = IgA, 2 = IgG)
  ) %>%
  filter(!is.na(Parameter_clean))  # Remove any rows where extraction failed

# Problem: There are 44 subjects, how should I do?
jags_filtered_paratyphi <- jags_processed_paratyphi %>%
  filter(Subject <= max(jags_processed_paratyphi$Subject, na.rm = TRUE))  # Keep only actual subjects


# Compute median for each parameter per subject and antigen type
param_medians_paratyphi <- jags_filtered_paratyphi %>%
  group_by(Subject, antigen_iso, Parameter_clean) %>%
  summarize(median_value = median(value), .groups = "drop")

# Reshape into wide format (one row per subject-antigen pair, with five parameters as columns)
param_medians_wide_paratyphi <- param_medians_paratyphi %>%
  pivot_wider(names_from = Parameter_clean, values_from = median_value)

# View the final structured dataframe
head(param_medians_wide_paratyphi)


## Typhi-->145 subjects
jags_processed_typhi <- jags_unpack_typhi %>%
  mutate(
    Parameter_clean = str_extract(Parameter, "^[a-zA-Z0-9]+"),  # Extract full parameter name (e.g., t1, y0, alpha)
    Subject = as.numeric(str_extract(Parameter, "(?<=\\[)\\d+")),  # Extract subject ID
    antigen_iso = as.numeric(str_extract(Parameter, "(?<=,)\\d+(?=\\])"))  # Extract antigen_iso (1 = IgA, 2 = IgG)
  ) %>%
  filter(!is.na(Parameter_clean))  # Remove any rows where extraction failed

# Problem: There are 44 subjects, how should I do?
jags_filtered_typhi <- jags_processed_typhi %>%
  filter(Subject <= max(jags_processed_typhi$Subject, na.rm = TRUE)-1)  # Keep only actual subjects


# Compute median for each parameter per subject and antigen type
param_medians_typhi <- jags_filtered_typhi %>%
  group_by(Subject, antigen_iso, Parameter_clean) %>%
  summarize(median_value = median(value), .groups = "drop")

# Reshape into wide format (one row per subject-antigen pair, with five parameters as columns)
param_medians_wide_typhi <- param_medians_typhi %>%
  pivot_wider(names_from = Parameter_clean, values_from = median_value)

# View the final structured dataframe
head(param_medians_wide_typhi)

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
### Using this 5 median parameters to plot predicted curve
## Generate the plot for 43 subjects
plot_paratyphi_curves <- graph.curve.params.subject(
  curve_params = param_medians_wide_paratyphi,
  antigen_isos = unique(param_medians_wide_paratyphi$antigen_iso),
  verbose = TRUE,
  show_all_curves = TRUE,  # Show individual subject curves
  alpha_samples = 0.3  # Transparency of individual curves
)

# Display the plot
print(plot_paratyphi_curves)

################################################################################
### Based on predicted curve, get predicted_result for each days since fever onset
## Create a Mapping Table and Update Values

# Step 1: Create mapping for id -> Subject (1 to 43)
unique_ids <- unique(data_paratyphi$id)  # Get unique subject IDs
subject_mapping <- data.frame(
  id = unique_ids,
  Subject = seq_along(unique_ids)  # Assign numbers 1 to 43
)

# Step 2: Convert antigen_iso (1 → HlyE_IgA, 2 → HlyE_IgG)
param_medians_wide_paratyphi <- param_medians_wide_paratyphi %>%
  mutate(antigen_iso = case_when(
    antigen_iso == 1 ~ "HlyE_IgA",
    antigen_iso == 2 ~ "HlyE_IgG"
  ))

# Step 3: Update the original dataset to match subjects
# Convert antigen_iso to character in both datasets for consistent join
data_paratyphi_update <- 
  data_paratyphi|>
  mutate(antigen_iso = case_when(
    antigen_iso == 1 ~ "HlyE_IgA",
    antigen_iso == 2 ~ "HlyE_IgG",
    TRUE ~ as.character(antigen_iso)  # Ensure all are character type
  ))|>
  left_join(subject_mapping,by=c("id"))

# Ensure antigen_iso in param_medians_wide_paratyphi is also character
param_medians_wide_paratyphi <- param_medians_wide_paratyphi %>%
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
data_paratyphi_update <- data_paratyphi_update %>%
  left_join(param_medians_wide_paratyphi, by = c("Subject", "antigen_iso")) %>%
  rowwise() %>%
  mutate(predicted_result = ab(dayssincefeveronset, y0, y1, t1, alpha, shape)) %>%
  ungroup()

# View the updated dataset
head(data_paratyphi_update)

################################################################################
### Compute residuals and re-organize data

data_paratyphi_update <- 
  data_paratyphi_update |>
  mutate(
    residual = result - predicted_result,  # Regular residual
    abs_residual = abs(result - predicted_result)  # Absolute residual
  )|>
  select(Country,id,sample_id,bldculres,antigen_iso,studyvisit,dayssincefeveronset,
         visit_num,result,predicted_result,residual,abs_residual)

# View the updated dataset
head(data_paratyphi_update)

################################################################################
### To plot residuals, faceted by person
## Do similar steps what I did above??
## If I do similar steps, then do I need to use abs_residual?
