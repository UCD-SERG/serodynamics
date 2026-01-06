#!/bin/bash
set -e

echo "Setting up serodynamics development environment..."

# Update package list
echo "Updating package list..."
apt-get update

# Install JAGS (required for serodynamics)
echo "Installing JAGS..."
apt-get install -y jags

# Install system dependencies for R packages
echo "Installing system dependencies..."
apt-get install -y \
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
  libgit2-dev

# Install Quarto
echo "Installing Quarto..."
QUARTO_VERSION="1.6.40"  # Updated to latest stable version (January 2026)
wget -q https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb
dpkg -i quarto-${QUARTO_VERSION}-linux-amd64.deb
rm quarto-${QUARTO_VERSION}-linux-amd64.deb

# Install R packages needed for development
echo "Installing R development packages..."
Rscript -e "install.packages(c('devtools', 'roxygen2', 'testthat', 'lintr', 'spelling', 'covr', 'rcmdcheck', 'pak'), repos = 'https://cloud.r-project.org')"

# Install rjags from source (required for JAGS interface)
echo "Installing rjags..."
Rscript -e "install.packages('rjags', repos = 'https://cloud.r-project.org', type = 'source')"

# Install package dependencies
echo "Installing package dependencies..."
Rscript -e "if (!requireNamespace('pak', quietly = TRUE)) install.packages('pak', repos = 'https://cloud.r-project.org'); pak::local_install_dev_deps(dependencies = TRUE)"

# Verify JAGS installation
echo "Verifying JAGS installation..."
Rscript -e "library(rjags); library(runjags); runjags::testjags()"

# Clean up
echo "Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Development environment setup complete!"
echo ""
echo "You can now:"
echo "  - Run 'devtools::load_all()' to load the package"
echo "  - Run 'devtools::test()' to run tests"
echo "  - Run 'devtools::check()' to check the package"
echo "  - Use VS Code tasks (Ctrl+Shift+P -> Tasks: Run Task)"
