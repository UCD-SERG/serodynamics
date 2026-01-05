# Experiment Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PAK_PREFER_BINARY Experiment Setup                       │
└─────────────────────────────────────────────────────────────────────────────┘

TRIGGER
────────────────────────────────────────────────────────────────────────────
  • PR to copilot/test-pak-prefer-binary-option branch
  • Manual workflow_dispatch from Actions tab
                                 │
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    ▼                         ▼
      ┌─────────────────────┐    ┌──────────────────────┐
      │   CONTROL GROUP     │    │  TREATMENT GROUP     │
      │   (Default PAK)     │    │  PAK_PREFER_BINARY   │
      │                     │    │     = "false"        │
      └─────────────────────┘    └──────────────────────┘
                │                            │
                │                            │
        ┌───────┴───────┐            ┌──────┴───────┐
        │ 5 Platform    │            │ 5 Platform   │
        │ Combinations  │            │ Combinations │
        └───────────────┘            └──────────────┘

PLATFORM MATRIX (Each Workflow)
────────────────────────────────────────────────────────────────────────────
  1. macOS-latest    + R release
  2. Windows-latest  + R release
  3. Ubuntu-latest   + R devel
  4. Ubuntu-latest   + R release
  5. Ubuntu-latest   + R oldrel-1

INSTRUMENTATION (Each Job)
────────────────────────────────────────────────────────────────────────────
  Step 1: Install JAGS (platform-specific)
  Step 2: Checkout code
  Step 3: ⏱️  Record workflow start time
  Step 4: Setup pandoc
  Step 5: Setup R
  Step 6: ⏱️  Record dependency installation start time
  Step 7: 📦 Install R dependencies (setup-r-dependencies)
  Step 8: ⏱️  Record dependency installation end time + calculate duration
  Step 9: 🔍 Check installed packages and installation type
  Step 10: Install rjags
  Step 11: ✅ Run R CMD check
  Step 12: ⏱️  Record workflow end time + display timing summary

METRICS COLLECTED
────────────────────────────────────────────────────────────────────────────
  ⏱️  Timing:
     • Total workflow duration (start to finish)
     • Dependency installation duration (setup-r-dependencies step)
  
  📦 Package Installation:
     • Package list with versions
     • Build information (indicates binary vs source)
     • PAK_PREFER_BINARY setting value
     • pak package version
  
  ✅ Test Outcomes:
     • R CMD check results
     • Pass/fail status
     • Warnings and notes

EXPECTED OUTPUT COMPARISON
────────────────────────────────────────────────────────────────────────────

Control Workflow Log Example:
  ┌────────────────────────────────────────────┐
  │ Dependency installation took 180 seconds   │
  │ === CONTROL TIMING SUMMARY ===            │
  │ PAK_PREFER_BINARY: default                │
  │ Dependency installation: 180 seconds      │
  │ Total workflow: 850 seconds               │
  │ ===============================           │
  └────────────────────────────────────────────┘

Experiment Workflow Log Example:
  ┌────────────────────────────────────────────┐
  │ Dependency installation took 420 seconds   │
  │ === EXPERIMENT TIMING SUMMARY ===         │
  │ PAK_PREFER_BINARY: false                  │
  │ Dependency installation: 420 seconds      │
  │ Total workflow: 1090 seconds              │
  │ =================================         │
  └────────────────────────────────────────────┘

ANALYSIS FLOW
────────────────────────────────────────────────────────────────────────────
  1. View workflow runs in GitHub Actions tab
  2. Extract timing data from each job's logs
  3. Record in EXPERIMENT_RESULTS_TEMPLATE.md
  4. Use experiment_helper.sh to calculate differences
  5. Compare package installation methods
  6. Verify test outcome consistency
  7. Document findings and recommendations

DOCUMENTATION STRUCTURE
────────────────────────────────────────────────────────────────────────────
  📄 EXPERIMENT_README.md
     └─→ Quick start guide for users
  
  📄 EXPERIMENT_PAK_PREFER_BINARY.md
     └─→ Detailed methodology, background, and analysis guide
  
  📄 EXPERIMENT_RESULTS_TEMPLATE.md
     └─→ Structured template for recording results
  
  📄 EXPERIMENT_SUMMARY.md
     └─→ Complete overview of experiment setup
  
  📄 EXPERIMENT_ARCHITECTURE.md (this file)
     └─→ Visual architecture and flow diagram
  
  🔧 experiment_helper.sh
     └─→ Interactive timing comparison tool

FILE LOCATIONS
────────────────────────────────────────────────────────────────────────────
  /.github/workflows/
    ├── R-CMD-check.yaml              (Original - unchanged)
    ├── R-CMD-check-control.yaml      (NEW - Control group)
    └── R-CMD-check-experiment.yaml   (NEW - Treatment group)
  
  /
    ├── EXPERIMENT_README.md              (NEW - Quick start)
    ├── EXPERIMENT_PAK_PREFER_BINARY.md   (NEW - Detailed docs)
    ├── EXPERIMENT_RESULTS_TEMPLATE.md    (NEW - Results template)
    ├── EXPERIMENT_SUMMARY.md             (NEW - Overview)
    ├── EXPERIMENT_ARCHITECTURE.md        (NEW - This file)
    └── experiment_helper.sh              (NEW - Helper script)

KEY DIFFERENCE
────────────────────────────────────────────────────────────────────────────
The ONLY code difference between control and experiment workflows:

  Control:                    Experiment:
  ┌─────────────────┐        ┌──────────────────────────┐
  │ env:            │        │ env:                     │
  │   GITHUB_PAT    │        │   GITHUB_PAT             │
  │   R_KEEP_PKG... │        │   R_KEEP_PKG_SOURCE      │
  │                 │        │   PAK_PREFER_BINARY: "false" │ ← DIFFERENCE
  └─────────────────┘        └──────────────────────────┘

WORKFLOW TRIGGERS
────────────────────────────────────────────────────────────────────────────
  Both workflows trigger on:
    • workflow_dispatch (manual trigger)
    • pull_request to copilot/test-pak-prefer-binary-option branch
  
  Both workflows are isolated to this experiment branch to avoid
  interfering with the main R-CMD-check.yaml workflow.

SUCCESS CRITERIA
────────────────────────────────────────────────────────────────────────────
  The experiment is successful when we can answer:
    ✓ How much does PAK_PREFER_BINARY: "false" affect build time?
    ✓ Does it change package installation methods (binary vs source)?
    ✓ Are test outcomes consistent between control and experiment?
    ✓ Should we adopt this setting for production workflows?
```
