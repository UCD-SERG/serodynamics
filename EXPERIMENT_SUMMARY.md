# PAK_PREFER_BINARY Experiment - Complete Setup Summary

This document provides a complete overview of the experimental setup created to test the impact of the `PAK_PREFER_BINARY` environment variable on the R-CMD-check GitHub Actions workflow.

## Experiment Objective

Test whether setting `PAK_PREFER_BINARY: "false"` in the R-CMD-check workflow affects:
1. **Workflow execution time** - Does it make the workflow slower or faster?
2. **Package installation method** - Does it force source compilation vs binary installation?
3. **Test outcomes** - Are there any differences in test results?

## What Was Created

### 1. Experimental Workflows

Two workflow files were created to run the experiment in parallel:

#### `.github/workflows/R-CMD-check-control.yaml`
- **Purpose**: Control group with default PAK settings
- **Trigger**: Manual (workflow_dispatch) or PR to `copilot/test-pak-prefer-binary-option` branch
- **Environment**: Standard R-CMD-check setup (no PAK_PREFER_BINARY override)
- **Job name**: `CONTROL-default {os} ({r-version})`

#### `.github/workflows/R-CMD-check-experiment.yaml`
- **Purpose**: Treatment group testing PAK_PREFER_BINARY: "false"
- **Trigger**: Manual (workflow_dispatch) or PR to `copilot/test-pak-prefer-binary-option` branch
- **Environment**: Sets `PAK_PREFER_BINARY: "false"` in env variables (line 32)
- **Job name**: `EXPERIMENT-no-binary {os} ({r-version})`

### 2. Instrumentation Added

Both workflows include identical instrumentation steps:

- **Step: "Record workflow start time"** (after checkout)
  - Records workflow start timestamp
  
- **Step: "Record dependency installation start time"** (before setup-r-dependencies)
  - Records when dependency installation begins
  
- **Step: "Record dependency installation end time and calculate duration"** (after setup-r-dependencies)
  - Calculates and displays dependency installation time
  - Stores duration in DEPS_DURATION environment variable
  
- **Step: "Check installed packages and installation type"** (after dependency installation)
  - Lists installed packages with version and build info
  - Shows PAK_PREFER_BINARY setting
  - Displays pak version if available
  
- **Step: "Record workflow end time and calculate total duration"** (final step, runs always)
  - Calculates total workflow duration
  - Displays summary with both dependency and total times

### 3. Test Matrix

Both workflows test across the same matrix configurations:
- macOS-latest with R release
- Windows-latest with R release
- Ubuntu-latest with R devel
- Ubuntu-latest with R release
- Ubuntu-latest with R oldrel-1

**Total**: 5 platform/version combinations × 2 workflows = 10 jobs per experiment run

### 4. Documentation Files

#### `EXPERIMENT_README.md`
Quick start guide for running and viewing the experiment results.

#### `EXPERIMENT_PAK_PREFER_BINARY.md`
Comprehensive documentation covering:
- Background on PAK_PREFER_BINARY
- Detailed experiment design
- Metrics collected
- How to run the experiment
- How to analyze results
- Expected outcomes
- Platform-specific considerations

#### `EXPERIMENT_RESULTS_TEMPLATE.md`
Structured template for recording and analyzing results with:
- Tables for each platform/R version combination
- Sections for timing, package installation, and test outcomes
- Conclusion and recommendation sections

#### `EXPERIMENT_SUMMARY.md` (this file)
Complete overview of the experimental setup.

### 5. Analysis Tools

#### `experiment_helper.sh`
Interactive bash script that:
- Provides instructions on where to find timing data
- Calculates timing differences
- Computes percentage changes
- Helps users extract and compare metrics

## How the Experiment Works

### Workflow Execution Flow

1. **Trigger**: When the PR is created/updated or manually triggered
2. **Parallel Execution**: Both control and experiment workflows run simultaneously
3. **Platform Matrix**: Each workflow runs on 5 different OS/R version combinations
4. **Instrumentation**: Each job records timing and package installation details
5. **Results**: Logs contain structured output for easy comparison

### Key Differences Between Control and Experiment

The **only** difference between the two workflows is line 32 in the experiment workflow:

```yaml
# Control workflow (.github/workflows/R-CMD-check-control.yaml)
env:
  GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
  R_KEEP_PKG_SOURCE: yes
  # PAK_PREFER_BINARY not set (uses default)

# Experiment workflow (.github/workflows/R-CMD-check-experiment.yaml)
env:
  GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
  R_KEEP_PKG_SOURCE: yes
  PAK_PREFER_BINARY: "false"  # ← Only difference
```

## Running the Experiment

### Automatic Trigger (Current Setup)
The workflows will automatically run when:
- This PR (to branch `copilot/test-pak-prefer-binary-option`) is created
- Changes are pushed to this PR
- The PR is synchronized

### Manual Trigger
You can also manually trigger either workflow:
1. Go to GitHub Actions tab
2. Select "R-CMD-check-control" or "R-CMD-check-experiment"
3. Click "Run workflow" button
4. Select branch: `copilot/test-pak-prefer-binary-option`
5. Click "Run workflow"

## Analyzing Results

### Step 1: Access Workflow Runs
1. Navigate to [Actions tab](../../actions) in GitHub
2. Find the latest runs of both workflows
3. Click on each workflow run to see the job matrix

### Step 2: Examine Each Job
For each platform/R version combination:
1. Click on the job (e.g., "CONTROL-default ubuntu-latest (release)")
2. Expand relevant step logs:
   - "Record dependency installation end time" - shows dependency time
   - "Check installed packages and installation type" - shows package details
   - "Record workflow end time and calculate total duration" - shows summary

### Step 3: Extract Metrics
Look for these lines in the logs:

**Dependency Installation Time:**
```
Dependency installation took 180 seconds
```

**Total Workflow Time:**
```
Total workflow: 850 seconds
```

**PAK Setting:**
```
PAK_PREFER_BINARY: false
```
or
```
PAK_PREFER_BINARY: 
```

### Step 4: Record and Compare
Use `EXPERIMENT_RESULTS_TEMPLATE.md` to systematically record all metrics, then compare:
- Control vs Experiment timing differences
- Package installation methods
- Test outcome consistency

### Step 5: Calculate Differences
Use the `experiment_helper.sh` script to help calculate:
- Absolute time differences (seconds)
- Percentage changes
- Platform-specific impacts

## Expected Results

### Hypothesis

Setting `PAK_PREFER_BINARY: "false"` will:

1. **On Ubuntu/Linux**: 
   - ⬆️ Increase build time significantly (30-100%+)
   - 🔧 Force many packages to build from source
   - 📦 Show more compilation output in logs
   
2. **On Windows/macOS**:
   - ⬆️ Moderate increase in build time (10-30%)
   - 📦 Some packages may still use binaries
   - 🔧 Limited source compilation

3. **Test Outcomes**:
   - ✅ Should be identical across control and experiment
   - ⚠️ If different, indicates platform-specific issues

### Success Criteria

The experiment is successful if we can clearly determine:
1. **Performance impact** of PAK_PREFER_BINARY: "false" on each platform
2. **Installation method changes** (binary vs source)
3. **Test consistency** between control and experiment

## Decision Framework

After analyzing results, use these guidelines:

### Add PAK_PREFER_BINARY: "false" to production if:
- ✅ Test outcomes reveal platform-specific issues when using binaries
- ✅ Source builds catch important compilation warnings/errors
- ✅ Time increase is acceptable for improved reliability
- ✅ Specific platforms benefit from source builds

### Keep default PAK settings if:
- ✅ Test outcomes are identical
- ✅ No benefit observed from source builds
- ✅ Time increase is significant without compensating value
- ✅ Binary packages work reliably

### Use selectively if:
- ✅ Only certain platforms benefit (e.g., Ubuntu only)
- ✅ Specific R versions require source builds
- ✅ Conditional logic would improve overall efficiency

## Files and Their Purposes

| File | Purpose | Audience |
|------|---------|----------|
| `.github/workflows/R-CMD-check-control.yaml` | Control workflow | GitHub Actions |
| `.github/workflows/R-CMD-check-experiment.yaml` | Experiment workflow | GitHub Actions |
| `EXPERIMENT_README.md` | Quick start guide | Users running experiment |
| `EXPERIMENT_PAK_PREFER_BINARY.md` | Detailed documentation | Users analyzing results |
| `EXPERIMENT_RESULTS_TEMPLATE.md` | Results recording template | Users documenting findings |
| `EXPERIMENT_SUMMARY.md` | Complete overview (this file) | All stakeholders |
| `experiment_helper.sh` | Timing calculation tool | Users analyzing metrics |

## Cleanup After Experiment

Once the experiment is complete and results are documented:

1. **Keep** (if valuable for future reference):
   - `EXPERIMENT_PAK_PREFER_BINARY.md` - Documentation of what was tested
   - `EXPERIMENT_RESULTS_TEMPLATE.md` - Filled with actual results

2. **Delete** (if no longer needed):
   - `.github/workflows/R-CMD-check-control.yaml` - Temporary control workflow
   - `.github/workflows/R-CMD-check-experiment.yaml` - Temporary experiment workflow
   - `EXPERIMENT_README.md` - Quick start (no longer needed)
   - `EXPERIMENT_SUMMARY.md` - This file (can be archived)
   - `experiment_helper.sh` - Helper script (no longer needed)

3. **Update** (based on findings):
   - `.github/workflows/R-CMD-check.yaml` - Add PAK_PREFER_BINARY if beneficial

## Questions or Issues?

If you encounter issues or have questions:
1. Review the detailed documentation in `EXPERIMENT_PAK_PREFER_BINARY.md`
2. Check workflow logs for error messages
3. Verify workflow triggers are configured correctly
4. Ensure you're viewing the correct branch's workflow runs

## Technical Notes

### Why Two Separate Workflows?
- Ensures identical execution timing (no sequential dependency)
- Easier to compare (parallel execution on same infrastructure)
- Clearer separation of control vs treatment
- Independent job naming for easy identification

### Why Limit to Experiment Branch?
- Prevents interference with main CI/CD pipeline
- Allows testing without affecting production workflows
- Easy cleanup after experiment concludes

### Why Include All Platforms?
- PAK behavior varies by platform
- Different package availability (RSPM on Ubuntu vs CRAN binaries)
- Comprehensive understanding of cross-platform impacts

---

**Experiment Created**: 2026-01-05
**Branch**: copilot/test-pak-prefer-binary-option
**Status**: Ready to run
