# PAK_PREFER_BINARY Experiment - Quick Start Guide

This directory contains experimental GitHub Actions workflows to test the impact of the `PAK_PREFER_BINARY` environment variable on R package installation in CI/CD.

## What is This Experiment?

We're testing whether setting `PAK_PREFER_BINARY: "false"` in the R-CMD-check workflow affects:
- ⏱️ Workflow execution time
- 📦 Package installation method (binary vs. source compilation)
- ✅ Test outcomes

## Files Created

1. **`.github/workflows/R-CMD-check-control.yaml`** - Control group (default PAK settings)
2. **`.github/workflows/R-CMD-check-experiment.yaml`** - Treatment group (`PAK_PREFER_BINARY: "false"`)
3. **`EXPERIMENT_PAK_PREFER_BINARY.md`** - Detailed experiment documentation
4. **`EXPERIMENT_README.md`** - This file

## How to Run the Experiment

The workflows will automatically run when this PR is created or updated. Both workflows will execute in parallel across multiple OS and R version combinations.

### Option 1: Automatic (Recommended)
- Simply create or update this PR
- Both workflows will run automatically
- Wait for completion (typically 15-30 minutes depending on configuration)

### Option 2: Manual Trigger
1. Go to the [Actions tab](../../actions)
2. Select "R-CMD-check-control" or "R-CMD-check-experiment"
3. Click "Run workflow"
4. Choose your branch and click "Run workflow"

## Viewing Results

1. Navigate to [Actions](../../actions) tab
2. Find the latest runs for both:
   - "R-CMD-check-control (default PAK settings)"
   - "R-CMD-check-experiment (PAK_PREFER_BINARY=false)"
3. Compare the results:
   - Check the summary sections in job logs
   - Look for timing differences
   - Review package installation details

### What to Look For

**In each job's logs:**
- 🔍 **"Record dependency installation end time"** step - shows dependency install duration
- 🔍 **"Check installed packages and installation type"** step - shows PAK settings and package info  
- 🔍 **"Record workflow end time and calculate total duration"** step - shows total timing summary

**Key Metrics:**
- Compare dependency installation times between control and experiment
- Compare total workflow times
- Check if packages are built from source vs binary
- Verify test outcomes are consistent

## Expected Outcomes

### Ubuntu (Linux)
- **Likely Impact**: Significant increase in build time with `PAK_PREFER_BINARY: "false"`
- **Why**: RSPM provides many binary packages for Ubuntu; forcing source builds requires compilation

### Windows & macOS  
- **Likely Impact**: Minimal to moderate increase
- **Why**: These platforms often get pre-compiled binaries from CRAN

## Next Steps After Experiment

1. **Review Results**: Compare timing and behavior between control and experiment
2. **Document Findings**: Note any significant differences
3. **Decide on Action**:
   - If `PAK_PREFER_BINARY: "false"` provides value (e.g., catches platform-specific issues), consider adding it
   - If it only increases build time without benefit, keep the default
4. **Clean Up**: Remove experimental workflows if not needed for ongoing testing

## Questions or Issues?

Refer to the detailed documentation in `EXPERIMENT_PAK_PREFER_BINARY.md` for more information about:
- Experiment methodology
- Detailed metrics explanation
- Analysis guidelines
- References and background

---

**Note**: These experimental workflows are triggered only on this PR branch to avoid interfering with the main R-CMD-check workflow used for regular CI.
