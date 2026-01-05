# Experiment Results Analysis Template

Use this template to record and analyze the results of the PAK_PREFER_BINARY experiment.

## Workflow Run Information

- **Date of Experiment**: _______________
- **Control Workflow Run**: [Link to workflow run]
- **Experiment Workflow Run**: [Link to workflow run]

## Results Summary

### 1. macOS-latest (R release)

| Metric | Control (default) | Experiment (PAK_PREFER_BINARY=false) | Difference |
|--------|------------------|-------------------------------------|------------|
| Dependency Installation Time | ___ seconds | ___ seconds | ___ seconds |
| Total Workflow Time | ___ seconds | ___ seconds | ___ seconds |
| Test Outcome | ☐ Pass ☐ Fail | ☐ Pass ☐ Fail | - |
| Notes | | | |

### 2. Windows-latest (R release)

| Metric | Control (default) | Experiment (PAK_PREFER_BINARY=false) | Difference |
|--------|------------------|-------------------------------------|------------|
| Dependency Installation Time | ___ seconds | ___ seconds | ___ seconds |
| Total Workflow Time | ___ seconds | ___ seconds | ___ seconds |
| Test Outcome | ☐ Pass ☐ Fail | ☐ Pass ☐ Fail | - |
| Notes | | | |

### 3. Ubuntu-latest (R devel)

| Metric | Control (default) | Experiment (PAK_PREFER_BINARY=false) | Difference |
|--------|------------------|-------------------------------------|------------|
| Dependency Installation Time | ___ seconds | ___ seconds | ___ seconds |
| Total Workflow Time | ___ seconds | ___ seconds | ___ seconds |
| Test Outcome | ☐ Pass ☐ Fail | ☐ Pass ☐ Fail | - |
| Notes | | | |

### 4. Ubuntu-latest (R release)

| Metric | Control (default) | Experiment (PAK_PREFER_BINARY=false) | Difference |
|--------|------------------|-------------------------------------|------------|
| Dependency Installation Time | ___ seconds | ___ seconds | ___ seconds |
| Total Workflow Time | ___ seconds | ___ seconds | ___ seconds |
| Test Outcome | ☐ Pass ☐ Fail | ☐ Pass ☐ Fail | - |
| Notes | | | |

### 5. Ubuntu-latest (R oldrel-1)

| Metric | Control (default) | Experiment (PAK_PREFER_BINARY=false) | Difference |
|--------|------------------|-------------------------------------|------------|
| Dependency Installation Time | ___ seconds | ___ seconds | ___ seconds |
| Total Workflow Time | ___ seconds | ___ seconds | ___ seconds |
| Test Outcome | ☐ Pass ☐ Fail | ☐ Pass ☐ Fail | - |
| Notes | | | |

## Package Installation Analysis

### Control (Default PAK Settings)

From the "Check installed packages and installation type" step:

- PAK_PREFER_BINARY value: _______________
- Evidence of binary installations: ☐ Yes ☐ No
- Evidence of source builds: ☐ Yes ☐ No
- Notable packages (binary): _______________
- Notable packages (source): _______________

### Experiment (PAK_PREFER_BINARY=false)

From the "Check installed packages and installation type" step:

- PAK_PREFER_BINARY value: _______________
- Evidence of binary installations: ☐ Yes ☐ No
- Evidence of source builds: ☐ Yes ☐ No
- Notable packages (binary): _______________
- Notable packages (source): _______________

## Overall Findings

### Performance Impact

- **Average time increase/decrease**: ___ seconds (___ %)
- **Most affected platform**: _______________
- **Least affected platform**: _______________

### Installation Method Changes

- Did PAK_PREFER_BINARY: "false" force source builds? ☐ Yes ☐ No ☐ Partial
- Which packages were affected? _______________
- Platform differences: _______________

### Test Outcome Consistency

- Were test results identical across control and experiment? ☐ Yes ☐ No
- If no, what differed? _______________

## Conclusions

### Key Takeaways

1. _______________
2. _______________
3. _______________

### Recommendations

Based on these results, the recommendation is to:

☐ **Add `PAK_PREFER_BINARY: "false"` to production workflow**
  - Reason: _______________

☐ **Keep current default PAK settings**
  - Reason: _______________

☐ **Use selectively (e.g., only on certain platforms)**
  - Reason: _______________
  - Platforms: _______________

### Next Steps

- [ ] _______________
- [ ] _______________
- [ ] _______________

## Additional Notes

_______________
_______________
_______________

---

**Completed by**: _______________
**Date**: _______________
