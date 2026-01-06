# Development Container Configuration

This directory contains the configuration for a containerized development environment for the serodynamics R package.

## What is a Dev Container?

Dev Containers allow you to use a Docker container as a full-featured development environment. This ensures that all developers work in a consistent environment with the same dependencies, tools, and configurations.

## Features

The serodynamics dev container includes:

- **R Environment**: Based on `rocker/tidyverse:latest` with R and tidyverse packages
- **JAGS**: Pre-installed JAGS 4.3.1 for Bayesian MCMC modeling
- **System Dependencies**: All required system libraries for R package development
- **R Development Tools**: devtools, roxygen2, testthat, lintr, spelling, covr
- **Quarto**: For rendering vignettes and documentation
- **VS Code Extensions**: R debugger, language support, GitHub Copilot, and more
- **Git & GitHub CLI**: For version control and GitHub integration
- **Node.js**: For MCP server support

## Quick Start

### Prerequisites

1. **Docker Desktop**: Install from https://www.docker.com/products/docker-desktop
2. **VS Code**: Install from https://code.visualstudio.com/
3. **Dev Containers Extension**: Install from VS Code marketplace

### Opening the Dev Container

1. Open the serodynamics repository in VS Code
2. Press `F1` or `Ctrl+Shift+P` (Cmd+Shift+P on macOS)
3. Select "Dev Containers: Reopen in Container"
4. Wait for the container to build (first time may take 5-10 minutes)
5. Once ready, you'll have a fully configured development environment

### Using the Dev Container

After opening in the container:

```r
# Load the package in development mode
devtools::load_all()

# Run tests
devtools::test()

# Check the package
devtools::check()

# Generate documentation
devtools::document()

# Lint the code
lintr::lint_package()
```

You can also use VS Code tasks (Ctrl+Shift+P -> "Tasks: Run Task") to run common operations.

## Container Configuration

### devcontainer.json

The main configuration file that defines:
- Base Docker image
- VS Code extensions to install
- VS Code settings
- Port forwarding (8787 for RStudio Server)
- Environment variables
- Post-create commands

### setup.sh

Runs after the container is created to:
- Install JAGS
- Install system dependencies
- Install Quarto
- Install R development packages
- Install package dependencies
- Verify JAGS installation

## RStudio Server Access

The container includes RStudio Server running on port 8787. To access it:

1. After the container starts, open http://localhost:8787 in your browser
2. Login with:
   - Username: `rstudio`
   - Password: `rstudio` (default)

## Customization

### Adding R Packages

Edit `setup.sh` to add more R packages to the base installation.

### Adding VS Code Extensions

Edit the `extensions` array in `devcontainer.json`.

### Adding System Dependencies

Edit the `apt-get install` command in `setup.sh`.

## Troubleshooting

### Container fails to build

1. Ensure Docker Desktop is running
2. Check that you have sufficient disk space (container is ~2-3 GB)
3. Try rebuilding: "Dev Containers: Rebuild Container"

### JAGS not found

The setup script should install JAGS automatically. If it fails:

1. Rebuild the container
2. Check the setup.sh logs for errors
3. Manually install JAGS in the container terminal

### R packages not installing

1. Check internet connection
2. Try installing manually: `Rscript -e "devtools::install_dev_deps()"`
3. Check for system dependency errors in the logs

### Performance issues

1. Allocate more resources to Docker Desktop (Settings -> Resources)
2. Close other containers and applications
3. Use a local R installation for better performance on simple tasks

## Benefits of Using Dev Containers

1. **Consistency**: Everyone works in the same environment
2. **Isolation**: Development environment is separate from your system
3. **Reproducibility**: Easy to share and recreate the environment
4. **Onboarding**: New contributors can start immediately
5. **Clean System**: No need to install R, JAGS, or dependencies on your system

## Alternative: Codespaces

This dev container configuration also works with GitHub Codespaces:

1. Navigate to the repository on GitHub
2. Click "Code" -> "Codespaces" -> "Create codespace on main"
3. Wait for the environment to set up
4. Start coding in your browser or connect from VS Code

## References

- [Dev Containers Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [Rocker Project](https://rocker-project.org/)
- [GitHub Codespaces](https://github.com/features/codespaces)
