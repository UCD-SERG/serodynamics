# PAK_PREFER_BINARY Experiment - Navigation Guide

Welcome! This guide helps you navigate the experiment files and documentation.

## 🚀 Getting Started (Start Here!)

**New to this experiment?** Read in this order:

1. **Start**: [EXPERIMENT_README.md](EXPERIMENT_README.md)
   - Quick overview and instructions to run the experiment
   - ~5 minute read

2. **Understand**: [EXPERIMENT_ARCHITECTURE.md](EXPERIMENT_ARCHITECTURE.md)
   - Visual diagram of how the experiment works
   - See the workflow structure and metrics
   - ~3 minute read

3. **Deep Dive**: [EXPERIMENT_PAK_PREFER_BINARY.md](EXPERIMENT_PAK_PREFER_BINARY.md)
   - Detailed methodology and background
   - Complete analysis guidelines
   - ~15 minute read

## 📁 File Directory

### Workflows (`.github/workflows/`)

| File | Purpose | When to Use |
|------|---------|-------------|
| `R-CMD-check-control.yaml` | Control workflow with default PAK settings | Auto-runs on PR; can trigger manually |
| `R-CMD-check-experiment.yaml` | Experiment workflow with PAK_PREFER_BINARY: "false" | Auto-runs on PR; can trigger manually |
| `R-CMD-check.yaml` | Original workflow (unchanged) | Normal CI/CD operations |

### Documentation Files (Repository Root)

| File | Purpose | When to Read |
|------|---------|--------------|
| `EXPERIMENT_INDEX.md` | **This file** - Navigation guide | First, to find what you need |
| `EXPERIMENT_README.md` | Quick start guide | Before running experiment |
| `EXPERIMENT_ARCHITECTURE.md` | Visual architecture diagram | To understand structure |
| `EXPERIMENT_PAK_PREFER_BINARY.md` | Detailed documentation | For methodology and analysis |
| `EXPERIMENT_SUMMARY.md` | Complete overview | For comprehensive understanding |
| `EXPERIMENT_RESULTS_TEMPLATE.md` | Results recording template | When recording experiment results |

### Tools (Repository Root)

| File | Purpose | When to Use |
|------|---------|-------------|
| `experiment_helper.sh` | Interactive timing comparison script | When analyzing results |

## 🎯 Quick Links by Task

### "I want to run the experiment"
→ Read: [EXPERIMENT_README.md](EXPERIMENT_README.md)  
→ Action: Trigger workflows from Actions tab or create/update this PR

### "I want to understand how it works"
→ Read: [EXPERIMENT_ARCHITECTURE.md](EXPERIMENT_ARCHITECTURE.md)  
→ See: Visual diagrams and flow charts

### "I want to analyze the results"
→ Read: [EXPERIMENT_PAK_PREFER_BINARY.md](EXPERIMENT_PAK_PREFER_BINARY.md) (Analysis section)  
→ Use: [EXPERIMENT_RESULTS_TEMPLATE.md](EXPERIMENT_RESULTS_TEMPLATE.md)  
→ Tool: `experiment_helper.sh`

### "I want the complete picture"
→ Read: [EXPERIMENT_SUMMARY.md](EXPERIMENT_SUMMARY.md)  
→ Contains: Everything in one comprehensive document

### "I want to know what to do next"
→ See: "Next Steps After Experiment" in [EXPERIMENT_SUMMARY.md](EXPERIMENT_SUMMARY.md#cleanup-after-experiment)

## 🔍 Finding Specific Information

### Background Information
- **What is PAK_PREFER_BINARY?** → [EXPERIMENT_PAK_PREFER_BINARY.md - Background](EXPERIMENT_PAK_PREFER_BINARY.md#background)
- **Why test this?** → [EXPERIMENT_README.md - What is This Experiment?](EXPERIMENT_README.md#what-is-this-experiment)

### Setup and Configuration
- **Workflow structure** → [EXPERIMENT_ARCHITECTURE.md](EXPERIMENT_ARCHITECTURE.md)
- **Platform matrix** → [EXPERIMENT_SUMMARY.md - Test Matrix](EXPERIMENT_SUMMARY.md#3-test-matrix)
- **Instrumentation details** → [EXPERIMENT_SUMMARY.md - Instrumentation Added](EXPERIMENT_SUMMARY.md#2-instrumentation-added)

### Running the Experiment
- **How to trigger** → [EXPERIMENT_README.md - How to Run](EXPERIMENT_README.md#how-to-run-the-experiment)
- **Manual trigger steps** → [EXPERIMENT_PAK_PREFER_BINARY.md - Running](EXPERIMENT_PAK_PREFER_BINARY.md#running-the-experiment)

### Analyzing Results
- **Where to find metrics** → [EXPERIMENT_README.md - Viewing Results](EXPERIMENT_README.md#viewing-results)
- **Recording template** → [EXPERIMENT_RESULTS_TEMPLATE.md](EXPERIMENT_RESULTS_TEMPLATE.md)
- **Comparison script** → `./experiment_helper.sh`
- **Expected outcomes** → [EXPERIMENT_PAK_PREFER_BINARY.md - Expected Results](EXPERIMENT_PAK_PREFER_BINARY.md#expected-results)

### Decision Making
- **Decision framework** → [EXPERIMENT_SUMMARY.md - Decision Framework](EXPERIMENT_SUMMARY.md#decision-framework)
- **Cleanup steps** → [EXPERIMENT_SUMMARY.md - Cleanup](EXPERIMENT_SUMMARY.md#cleanup-after-experiment)

## 📊 Experiment Workflow

```
1. READ
   └─→ EXPERIMENT_README.md (Quick Start)

2. UNDERSTAND
   └─→ EXPERIMENT_ARCHITECTURE.md (Visual Overview)

3. TRIGGER
   └─→ Create/Update PR or Manual trigger from Actions tab

4. MONITOR
   └─→ GitHub Actions tab (watch workflow progress)

5. COLLECT
   └─→ Extract metrics from workflow logs

6. RECORD
   └─→ Fill out EXPERIMENT_RESULTS_TEMPLATE.md

7. ANALYZE
   └─→ Use experiment_helper.sh to compare

8. DECIDE
   └─→ Follow decision framework in EXPERIMENT_SUMMARY.md

9. CLEANUP
   └─→ Remove experimental files or integrate findings
```

## 📝 Document Sizes

For your reference:

| Document | Lines | Words | Size |
|----------|-------|-------|------|
| EXPERIMENT_README.md | ~87 | ~870 | 3.5 KB |
| EXPERIMENT_ARCHITECTURE.md | ~165 | ~1,100 | 6.7 KB |
| EXPERIMENT_PAK_PREFER_BINARY.md | ~130 | ~1,300 | 5.1 KB |
| EXPERIMENT_SUMMARY.md | ~298 | ~2,600 | 10.5 KB |
| EXPERIMENT_RESULTS_TEMPLATE.md | ~136 | ~800 | 4.3 KB |
| EXPERIMENT_INDEX.md (this file) | ~135 | ~850 | 5.0 KB |

## 🎓 Learning Path

### Beginner (15 minutes)
1. EXPERIMENT_INDEX.md (this file) - 3 min
2. EXPERIMENT_README.md - 5 min
3. EXPERIMENT_ARCHITECTURE.md - 5 min
4. Trigger experiment - 2 min

### Intermediate (30 minutes)
1. All Beginner steps
2. EXPERIMENT_PAK_PREFER_BINARY.md - 15 min
3. Set up results tracking - 5 min

### Advanced (1 hour)
1. All Intermediate steps
2. EXPERIMENT_SUMMARY.md - 20 min
3. Review workflow YAML files - 10 min
4. Complete analysis with experiment_helper.sh - 10 min

## ❓ FAQ

**Q: Which file should I read first?**  
A: Start with EXPERIMENT_README.md for a quick overview.

**Q: Where are the workflows?**  
A: In `.github/workflows/R-CMD-check-control.yaml` and `R-CMD-check-experiment.yaml`

**Q: How do I run the experiment?**  
A: See EXPERIMENT_README.md section "How to Run the Experiment"

**Q: Where do I record results?**  
A: Use EXPERIMENT_RESULTS_TEMPLATE.md as your template

**Q: How do I compare timing results?**  
A: Run `./experiment_helper.sh` for interactive comparison

**Q: What's the difference between control and experiment?**  
A: Just one line: `PAK_PREFER_BINARY: "false"` in the experiment workflow

**Q: How long does the experiment take?**  
A: ~15-30 minutes for workflows to run, plus ~15-20 minutes for analysis

## 🔗 External Resources

- [pak package documentation](https://pak.r-lib.org/)
- [r-lib/actions GitHub Actions](https://github.com/r-lib/actions)
- [PAK environment variables](https://pak.r-lib.org/reference/pak-config.html)

## 📞 Need Help?

If you're stuck or have questions:
1. Review the relevant documentation file (use this index to find it)
2. Check the workflow logs for error messages
3. Verify you're on the correct branch: `copilot/test-pak-prefer-binary-option`
4. Ensure workflows are triggered correctly (PR or manual)

---

**Last Updated**: 2026-01-05  
**Experiment Status**: ✅ Ready to Run  
**Total Documentation**: 6 files, ~38 KB
