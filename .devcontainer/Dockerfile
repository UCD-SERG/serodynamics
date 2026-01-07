# Use the rocker/verse image as base (includes R, tidyverse, devtools, and more)
# This image includes R >= 4.1.0, RStudio, tidyverse packages, and TeX
FROM rocker/verse:latest

# Install system dependencies for R packages
RUN apt-get update && apt-get install -y \
    # JAGS for Bayesian modeling
    jags \
    # System libraries for R packages
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    # Additional utilities
    wget \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install rjags and runjags from source
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); \
    install.packages('rjags', type = 'source'); \
    install.packages('runjags', type = 'source')"

# Verify JAGS installation
RUN R -e "library(rjags); library(runjags); runjags::findJAGS(); runjags::testjags()"

# Set working directory
WORKDIR /workspace

# Install common R development packages that are always needed
# This helps reduce setup time after container is created
RUN R -e "install.packages(c('devtools', 'testthat', 'roxygen2', 'pkgdown', 'covr', 'lintr', 'spelling', 'rcmdcheck', 'rmarkdown', 'knitr'), repos = 'https://cloud.r-project.org')"

# The postCreateCommand in devcontainer.json will install project-specific dependencies
