# Development Container for serodynamics

This directory contains the configuration for a development container that provides a consistent, pre-configured environment for working on the serodynamics package.

## What's Included

The development container is based on `rocker/verse:latest` and includes:

- **R** (>= 4.1.0) with RStudio
- **JAGS** (4.3.1) - Required for Bayesian MCMC modeling
- **rjags** - R interface to JAGS
- **tidyverse** packages
- **System libraries** for common R packages (libcurl, libssl, libxml2, etc.)
- **Development tools**: devtools, testthat, roxygen2, pkgdown, covr, lintr, spelling, rcmdcheck

## Benefits

- **Persistent environment**: The container persists between sessions, so you don't need to reinstall R, JAGS, or dependencies each time
- **Consistent setup**: Everyone uses the same R version and system configuration
- **Faster startup**: After the initial build, subsequent sessions start much faster
- **GitHub Copilot integration**: Works seamlessly with GitHub Copilot Workspace

## How to Use

### In GitHub Copilot Workspace

GitHub Copilot Workspace will automatically detect the `.devcontainer/devcontainer.json` file and offer to use it. Simply accept the prompt to use the devcontainer.

### In Visual Studio Code

1. Install the "Dev Containers" extension
2. Open the repository in VS Code
3. When prompted, click "Reopen in Container"
   - Or use the Command Palette (F1) and select "Dev Containers: Reopen in Container"

### In GitHub Codespaces

GitHub Codespaces automatically uses the devcontainer configuration when you create a new codespace.

## Initial Setup

The first time you use the devcontainer, it will:

1. Build the Docker image (5-10 minutes)
2. Install project-specific R dependencies via `devtools::install_dev_deps()` (3-5 minutes)

Subsequent sessions will skip these steps and start immediately.

## Updating the Container

If you need to update the container (e.g., to add new system dependencies):

1. Edit `.devcontainer/Dockerfile`
2. Rebuild the container:
   - In VS Code: Command Palette → "Dev Containers: Rebuild Container"
   - In Codespaces: Stop and delete the codespace, then create a new one

## Troubleshooting

### Container fails to build

- Check that Docker has enough disk space and memory
- Review the build logs for specific errors
- Try rebuilding without cache: "Dev Containers: Rebuild Container Without Cache"

### R packages fail to install

- The `postCreateCommand` installs dependencies automatically
- If it fails, you can manually run: `Rscript -e 'devtools::install_dev_deps(dependencies = TRUE)'`

### JAGS not found

- The container includes JAGS pre-installed
- Verify with: `R -e 'runjags::testjags()'`
- If still not working, rebuild the container
