# PAK_PREFER_BINARY Experiment Documentation

## Overview

This experiment tests the impact of the `PAK_PREFER_BINARY` environment variable on the R-CMD-check GitHub Actions workflow.

## Background

The `PAK_PREFER_BINARY` environment variable controls the behavior of the `pak` package manager, which is used by `r-lib/actions/setup-r-dependencies` action to install R package dependencies.

- **`PAK_PREFER_BINARY: "true"`** (default): Prefers pre-compiled binary packages when available. This is generally faster as packages don't need to be compiled from source.
- **`PAK_PREFER_BINARY: "false"`**: Forces installation from source code, requiring compilation. This can be slower but ensures packages are built for the exact system configuration.

## Experiment Design

### Hypothesis
Setting `PAK_PREFER_BINARY: "false"` will:
1. Increase workflow execution time due to package compilation
2. Change package installation methods from binary to source
3. Potentially affect test outcomes if binary vs source builds differ

### Experimental Setup

Two workflow files have been created:

1. **Control Group**: `.github/workflows/R-CMD-check-control.yaml`
   - Uses default PAK settings (typically prefers binaries)
   - Runs on: workflow_dispatch and pull requests to experiment branch
   
2. **Treatment Group**: `.github/workflows/R-CMD-check-experiment.yaml`
   - Sets `PAK_PREFER_BINARY: "false"` in environment variables
   - Runs on: workflow_dispatch and pull requests to experiment branch

Both workflows include identical instrumentation to measure:

### Metrics Collected

1. **Timing Metrics**:
   - Total workflow execution time
   - Dependency installation time (setup-r-dependencies step)
   
2. **Package Installation Details**:
   - List of installed packages with versions
   - Package build information (indicates binary vs source)
   - PAK configuration settings
   
3. **Test Outcomes**:
   - R CMD check results
   - Test pass/fail status
   - Any warnings or notes generated

### Test Matrix

Both workflows test across multiple configurations:
- **macOS-latest** with R release
- **Windows-latest** with R release  
- **Ubuntu-latest** with R devel
- **Ubuntu-latest** with R release
- **Ubuntu-latest** with R oldrel-1

## Running the Experiment

### Method 1: Automatic Trigger (Recommended)
The workflows will automatically run when:
- A pull request is opened to the `copilot/test-pak-prefer-binary-option` branch
- Changes are pushed to an existing PR on that branch

### Method 2: Manual Trigger
You can manually trigger the workflows:
1. Go to Actions tab in GitHub
2. Select either "R-CMD-check-control" or "R-CMD-check-experiment"
3. Click "Run workflow"
4. Select the branch and click "Run workflow"

## Analyzing Results

### Step 1: Access Workflow Runs
1. Navigate to the repository's Actions tab
2. Look for recent runs of both control and experiment workflows
3. Click on each run to view details

### Step 2: Compare Timing
Look at the final step "Record workflow end time and calculate total duration" in each job's logs:
- Compare dependency installation times between control and experiment
- Compare total workflow times between control and experiment

### Step 3: Examine Package Installation
Look at the "Check installed packages and installation type" step:
- Check if PAK_PREFER_BINARY setting is correctly applied
- Examine the "Built" column in package info (shows R version and architecture - can indicate binary vs source)

### Step 4: Compare Test Outcomes
Check the R-CMD-check results:
- Do both workflows pass all tests?
- Are there any differences in warnings, notes, or errors?

## Expected Results

### If PAK_PREFER_BINARY: "false" has significant impact:
- Experiment workflow should take longer (especially on Linux/Ubuntu where binaries are most common)
- Package installation step should show compilation output
- Built information may show source builds

### If PAK_PREFER_BINARY: "false" has minimal impact:
- Timing differences might be small
- Many packages may still install as binaries (e.g., on Windows/macOS where CRAN provides binaries)
- Test outcomes should be identical

## Notes

1. **Platform Differences**: The impact of `PAK_PREFER_BINARY: "false"` may vary by platform:
   - Ubuntu/Linux: Larger impact (many packages available as binaries via RSPM)
   - Windows/macOS: Smaller impact (CRAN binaries are standard)

2. **Compilation Requirements**: Some packages (like rjags) are explicitly installed from source in this workflow regardless of PAK settings.

3. **Network Variability**: Some timing differences may be due to network conditions rather than build method.

## Cleanup

After the experiment is complete and results are analyzed, you can:
1. Delete the experimental workflow files if no longer needed
2. Update the main R-CMD-check.yaml with optimal settings if desired
3. Document findings in a GitHub issue or PR comment

## References

- [pak package documentation](https://pak.r-lib.org/)
- [r-lib/actions GitHub Actions](https://github.com/r-lib/actions)
- [PAK environment variables](https://pak.r-lib.org/reference/pak-config.html)
