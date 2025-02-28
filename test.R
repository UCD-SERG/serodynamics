### Draft of converting v9na.resid.r file

# Load necessary libraries
library(dplyr)
library(Hmisc)
library(ggplot2)
source("data-raw/graph-func.r")  # Loads `ab()` function
source("data-raw/minticks.r")    # Loads custom tick functions

# Function to fit antibody response model using precomputed parameters
fit_curve_to_individual <- function(data, params) {
  data$predicted <- sapply(data$dayssincefeveronset, function(t) {
    ab(t, params$y0, params$y1, params$t1, params$alpha, params$shape)
  })
  return(data)
}

# Function to compute residuals (Observed - Predicted)
compute_residuals <- function(data) {
  data <- data %>%
    mutate(residual = log10(result) - log10(predicted)) %>%
    select(person_id, dayssincefeveronset, result, predicted, residual)
  return(data)
}

# Function to plot residuals, faceted by person, for a random subset
plot_residuals <- function(data, sample_size = 30) {
  sampled_ids <- sample(unique(data$person_id), size = sample_size, replace = FALSE)
  sampled_data <- data %>% filter(person_id %in% sampled_ids)
  
  ggplot(sampled_data, aes(x = dayssincefeveronset, y = residual)) +
    geom_point(alpha = 0.5) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    facet_wrap(~ person_id, scales = "free") +
    labs(title = "Residuals by Person",
         x = "Days Since Fever Onset",
         y = "Residual (log scale)") +
    theme_minimal()
}


###############################################################################
# Example Usage:
# Assuming `run_mod()` returns a dataframe with `person_id` and model parameters
#run_mod_results <- run_mod(SEES_Case_Nepal)  # Generate model parameters, this is tricky part

# Load your dataset
SEES_Case_Nepal <- read.csv("SEES_Case_Nepal.csv")

# Convert time variable to numeric
SEES_Case_Nepal <- SEES_Case_Nepal %>%
  mutate(dayssincefeveronset = as.numeric(dayssincefeveronset))

fitted_data <- SEES_Case_Nepal %>%
  group_by(person_id) %>%
  group_split() %>%
  map2(run_mod_results, fit_curve_to_individual) %>%
  bind_rows()

# Compute residuals
residuals_data <- compute_residuals(fitted_data)

# Plot residuals for a random sample of individuals
plot_residuals(residuals_data, sample_size = 30)
