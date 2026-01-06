# Development Guide for serodynamics

This guide provides comprehensive information on setting up your development environment and contributing to the serodynamics R package.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Development Environment Setup](#development-environment-setup)
3. [Model Context Protocol (MCP)](#model-context-protocol-mcp)
4. [Development Workflow](#development-workflow)
5. [Testing and Quality Assurance](#testing-and-quality-assurance)
6. [Contributing](#contributing)

## Quick Start

### Option 1: Dev Container (Recommended)

The fastest way to get started with a fully configured environment:

```bash
# Prerequisites: Docker Desktop and VS Code with Dev Containers extension
# 1. Open this repository in VS Code
# 2. Click "Reopen in Container" when prompted
# 3. Wait for the container to build (~5-10 minutes first time)
# 4. Start developing!
```

See [.devcontainer/README.md](.devcontainer/README.md) for details.

### Option 2: Local Setup

If you prefer to install dependencies locally, follow the [Critical Setup Requirements](#critical-setup-requirements) section.

## Development Environment Setup

### Prerequisites

- **R** (>= 4.1.0) - Statistical computing language
- **JAGS** (>= 4.3.1) - Just Another Gibbs Sampler for Bayesian MCMC
- **Git** - Version control
- **Node.js** (optional) - For MCP server support
- **RStudio** or **VS Code** - Recommended IDEs

### Critical Setup Requirements

#### 1. Install R

**Ubuntu/Linux:**
```bash
sudo apt-get update
sudo apt-get install -y software-properties-common dirmngr
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
sudo apt-get update
sudo apt-get install -y r-base r-base-dev
```

**macOS:**
```bash
brew install r
```

**Windows:**
Download from https://cran.r-project.org/bin/windows/base/

#### 2. Install JAGS

**Ubuntu/Linux:**
```bash
sudo apt-get update && sudo apt-get install -y jags
```

**macOS:**
Download from https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Mac%20OS%20X/JAGS-4.3.1.pkg

**Windows:**
Download from https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Windows/JAGS-4.3.1.exe

#### 3. Install System Dependencies (Linux/macOS)

**Ubuntu/Linux:**
```bash
sudo apt-get install -y \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libfontconfig1-dev \
  libharfbuzz-dev \
  libfribidi-dev \
  libfreetype6-dev \
  libpng-dev \
  libtiff5-dev \
  libjpeg-dev
```

**macOS:**
```bash
brew install pkg-config cairo
```

#### 4. Install R Development Packages

```r
# Install devtools
install.packages("devtools", repos = "https://cloud.r-project.org")

# Install all package dependencies
devtools::install_dev_deps(dependencies = TRUE)

# Install rjags from source
install.packages("rjags", repos = "https://cloud.r-project.org", type = "source")
```

#### 5. Verify Installation

```r
library(rjags)
library(runjags)
runjags::testjags()  # Should show JAGS is working
```

### VS Code Configuration

The repository includes pre-configured VS Code settings in `.vscode/`:

- **settings.json** - R-specific editor settings, file associations
- **extensions.json** - Recommended extensions for R development
- **tasks.json** - Quick tasks for common operations

#### Recommended Extensions

Open VS Code and install the recommended extensions:
- R Debugger (`rdebugger.r-debugger`)
- R Language Support (`reditorsupport.r`)
- GitHub Copilot (`github.copilot`)
- GitHub Copilot Chat (`github.copilot-chat`)
- Quarto (`quarto.quarto`)
- YAML (`redhat.vscode-yaml`)
- Markdown All in One (`yzhang.markdown-all-in-one`)
- Code Spell Checker (`streetsidesoftware.code-spell-checker`)
- GitLens (`eamodio.gitlens`)

#### Using VS Code Tasks

Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS) and select "Tasks: Run Task":

- **R: Load Package** - Load package in development mode
- **R: Document Package** - Generate documentation from roxygen2 comments
- **R: Run Tests** - Execute all tests
- **R: Check Package** - Run R CMD check
- **R: Lint Package** - Check code style
- **R: Spell Check** - Check spelling
- **R: Build README** - Render README.Rmd
- **R: Install Dependencies** - Install all package dependencies

## Model Context Protocol (MCP)

The repository includes MCP server configurations in `.github/mcp/mcp-config.json` that enhance AI-assisted development.

### Configured MCP Servers

1. **Filesystem Server** - Read/write repository files, search code
2. **GitHub Server** - Check CI/CD status, manage PRs and issues
3. **Git Server** - Version control operations (status, diff, commit)
4. **Brave Search Server** - Look up R documentation and CRAN resources

### Setup MCP

#### Prerequisites
```bash
# Ensure Node.js is installed
node --version  # Should be >= 18.x
npm --version
```

#### Environment Variables

Set these environment variables for MCP servers:

```bash
# GitHub token (required for GitHub MCP server)
export GITHUB_TOKEN="your_github_personal_access_token"

# Brave API key (optional, for web search)
export BRAVE_API_KEY="your_brave_api_key"
```

#### Using MCP with GitHub Copilot

MCP is automatically detected by GitHub Copilot in VS Code when the configuration file is present in `.github/mcp/mcp-config.json`.

See [.github/mcp/README.md](.github/mcp/README.md) for detailed setup instructions.

## Development Workflow

### 1. Load the Package

```r
devtools::load_all()
```

This loads the package in development mode, making all functions available for testing.

### 2. Make Code Changes

Edit R source files in the `R/` directory. Follow the [code style guidelines](#code-style-guidelines).

### 3. Document Your Changes

After modifying roxygen2 comments:

```r
devtools::document()
```

**Important:** Never edit files in `man/` or `NAMESPACE` directly. They are auto-generated.

### 4. Test Your Changes

```r
# Run all tests
devtools::test()

# Run specific test file
testthat::test_file("tests/testthat/test-your-feature.R")
```

### 5. Check Code Quality

```r
# Lint your code
lintr::lint_package()

# Spell check
spelling::spell_check_package()
```

### 6. Run R CMD Check

Before committing:

```r
devtools::check()
```

This runs the full package validation suite (takes 5-10 minutes).

### 7. Update Documentation

If you edited `README.Rmd`:

```r
rmarkdown::render("README.Rmd")
```

### 8. Commit Your Changes

```bash
git add .
git commit -m "Your descriptive commit message"
git push
```

## Testing and Quality Assurance

### Test Structure

Tests are in `tests/testthat/` and use testthat 3.0+ with snapshot testing.

### Writing Tests

```r
test_that("your feature works correctly", {
  # Use seed for reproducible tests
  withr::local_seed(123)
  
  # Your test code
  result <- your_function(input)
  
  # Assertions
  expect_equal(result, expected_value)
})
```

### Snapshot Testing

For MCMC output validation:

```r
test_that("JAGS output is consistent", {
  withr::local_seed(123)
  
  output <- run_jags_model(...)
  
  # Create snapshot
  expect_snapshot_value(output, style = "json2")
})
```

### Platform-Specific Tests

Use `variant` for platform-specific snapshots:

```r
expect_snapshot_value(
  platform_dependent_output,
  variant = Sys.info()[["sysname"]]
)
```

### Continuous Integration

All PRs must pass these checks:

- ✅ R CMD check (Ubuntu, macOS, Windows)
- ✅ Linting (changed files only)
- ✅ Test coverage
- ✅ Spelling
- ✅ Documentation sync
- ✅ NEWS.md updated
- ✅ Version incremented

## Code Style Guidelines

### General Principles

- Follow the [tidyverse style guide](https://style.tidyverse.org)
- Use native pipe `|>` (not `%>%`)
- Use snake_case for naming (acronyms may be uppercase, e.g., `prep_IDs`)
- Two spaces for indentation (no tabs)
- Maximum line length: 80 characters (soft), 100 characters (hard)

### Function Documentation

Use roxygen2 for all exported functions:

```r
#' Brief function description
#'
#' Detailed description of what the function does.
#'
#' @param x Description of parameter x
#' @param y Description of parameter y
#'
#' @returns Description of return value
#'
#' @examples
#' your_function(1, 2)
#'
#' @export
your_function <- function(x, y) {
  # Function body
}
```

### User-Facing Messages

Use `cli` package functions:

```r
# Information
cli::cli_inform("Operation completed")

# Warning
cli::cli_warn("Potential issue detected")

# Error
cli::cli_abort("Operation failed")
```

**Never use** `message()`, `warning()`, or `stop()` in package code.

### Dependencies

- Use `::` to call functions from other packages
- Don't use `library()` or `require()` in package code
- Add dependencies to DESCRIPTION (Imports or Suggests)

### Avoid Code Duplication

Don't copy-paste code. Instead, create helper functions:

```r
# Bad - duplicated code
result1 <- transform_data(data1, param = "A")
result2 <- transform_data(data2, param = "A")

# Good - extract common pattern
process_with_param_a <- function(data) {
  transform_data(data, param = "A")
}
result1 <- process_with_param_a(data1)
result2 <- process_with_param_a(data2)
```

## Contributing

### Pull Request Checklist

Before submitting a PR, ensure:

- [ ] Tests pass locally (`devtools::test()`)
- [ ] R CMD check passes (`devtools::check()`)
- [ ] Code is linted (`lintr::lint_package()`)
- [ ] Spelling is correct (`spelling::spell_check_package()`)
- [ ] Documentation is up to date (`devtools::document()`)
- [ ] README.md is updated (if you edited README.Rmd)
- [ ] NEWS.md has an entry for your changes
- [ ] DESCRIPTION version is incremented (`usethis::use_version()`)

### Getting Help

- 📖 See `.github/copilot-instructions.md` for comprehensive repository guidance
- 🐛 Report bugs via GitHub Issues
- 💬 Ask questions in GitHub Discussions
- 📧 Contact maintainers (see DESCRIPTION file)

## Resources

- [R Packages Book](https://r-pkgs.org/) - Comprehensive guide to R package development
- [tidyverse Style Guide](https://style.tidyverse.org) - R code style conventions
- [testthat Documentation](https://testthat.r-lib.org/) - Testing framework
- [roxygen2 Documentation](https://roxygen2.r-lib.org/) - Documentation generation
- [devtools Documentation](https://devtools.r-lib.org/) - Package development tools
- [JAGS Documentation](https://mcmc-jags.sourceforge.io/) - Bayesian MCMC with JAGS

## License

See [LICENSE.md](LICENSE.md) for license information.
