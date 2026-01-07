#!/bin/bash
# Post-creation setup script for the serodynamics dev container

set -e  # Exit on error

echo "Setting up serodynamics development environment..."

# Set up persistent bash history
echo "Configuring bash history persistence..."
mkdir -p /commandhistory
touch /commandhistory/.bash_history
ln -sf /commandhistory/.bash_history /home/rstudio/.bash_history

# Install project-specific R dependencies
echo "Installing R package dependencies..."
Rscript -e 'devtools::install_dev_deps(dependencies = TRUE)'

echo "Setup complete! The environment is ready for development."
