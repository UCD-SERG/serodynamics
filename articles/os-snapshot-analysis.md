# Analysis of OS-Specific Snapshot Variants

## Summary

OS-specific snapshot variants exist for JAGS MCMC output because **JAGS
does not produce bit-for-bit identical results across different
operating systems**, even when using identical random number generator
(RNG) seeds, algorithms, and model specifications.

## Key Findings

### 1. Linux and Windows Are Identical

All snapshot files for Linux and Windows are **100% identical** (0 byte
differences):

``` bash
# Verified for all snapshot files:
diff tests/testthat/_snaps/linux/run_mod/*.csv tests/testthat/_snaps/windows/run_mod/*.csv
# Result: No differences found
```

This suggests: - Linux and Windows use similar or identical: -
Floating-point arithmetic implementations - Mathematical library
implementations (libm) - Compiler optimization strategies - JAGS binary
compilation settings

### 2. macOS Differs from Linux/Windows

macOS (darwin) snapshots diverge from Linux/Windows, starting at
specific iterations:

**Example from `kinetics.csv`:** - Iterations 1-18: All three platforms
**identical** - Iteration 19: Divergence begins for parameter
`alpha[6,1]` (person 6) - Darwin: `alpha[6,1] = 0.0183156` -
Linux/Windows: `alpha[6,1] = 0.0160759`

The divergence affects all parameters for person 6 from iteration 19
onwards: - `alpha[6,1]`: 0.0183156 vs 0.0160759 - `shape[6,1]`: 1.36788
vs 1.33649 - `t1[6,1]`: 2.71828 vs 3.34814 - `y0[6,1]`: 2.71828 vs
5.30265 - `y1[6,1]`: 1099.35 vs 578.7

### 3. RNG State Is Identical Across Platforms

Despite the divergence in MCMC samples, the RNG state is identical
across all platforms:

    ".RNG.state" <- c(15587, 26869, 21639)

This confirms that: - The RNG **seed and algorithm** are working
correctly - The RNG **produces the same random numbers** on all
platforms - The divergence occurs in the **MCMC sampling algorithm**,
not the RNG

## Root Cause Analysis

### Why JAGS Produces Platform-Dependent Results

JAGS uses the random numbers from the RNG in complex mathematical
operations (log, exp, pow, step functions, etc.) that involve:

1.  **Floating-Point Arithmetic**
    - IEEE 754 allows platform-specific implementations
    - Different CPUs may use different precision (x87 80-bit vs SSE
      64-bit on x86)
    - Rounding modes can differ
    - Order of operations affects accumulated rounding errors
2.  **Mathematical Function Libraries**
    - [`log()`](https://rdrr.io/r/base/Log.html),
      [`exp()`](https://rdrr.io/r/base/Log.html), `pow()`
      implementations differ across platforms
    - macOS uses different libm than Linux glibc
    - Windows uses Microsoft’s math library
    - These differences compound through iterative MCMC sampling
3.  **Compiler Optimizations**
    - Different compilers (GCC, Clang, MSVC) optimize differently
    - Instruction reordering can change accumulation of rounding errors
    - Vectorization strategies differ (SSE, AVX on different platforms)
    - Fast math flags can affect precision
4.  **MCMC Chain Propagation**
    - Small differences in early iterations propagate
    - Iteration 19 is where accumulated differences cross a threshold
    - Subsequent iterations build on these differences

### Why adapt=0 Doesn’t Eliminate Differences

The test uses `adapt = 0` to minimize platform differences, but this
only disables JAGS’s adaptive tuning of proposal distributions. It
doesn’t eliminate: - Floating-point precision differences - Mathematical
library implementation differences - Compiler optimization differences

## Current Snapshot Strategy

The repository currently maintains:

1.  **Base snapshots** (`tests/testthat/_snaps/run_mod/`) - Match
    Linux/Windows
2.  **darwin variants** (`tests/testthat/_snaps/darwin/run_mod/`) -
    macOS-specific
3.  ~~**linux variants** (`tests/testthat/_snaps/linux/run_mod/`) -
    Identical to base~~ (Removed in consolidation)
4.  ~~**windows variants** (`tests/testthat/_snaps/windows/run_mod/`) -
    Identical to linux~~ (Removed in consolidation)

This was **redundant** because: - Windows snapshots duplicated Linux
snapshots - Linux snapshots duplicated base snapshots - Only darwin
snapshots provide unique value

## Implemented Solution

### Option 1: Consolidate Redundant Snapshots

We **removed duplicate snapshots for Linux and Windows**, keeping
only: - **Base snapshots** (no variant) - Used by Linux and Windows -
**darwin variants** - Used by macOS only

**Benefits:** - Eliminates ~50% of snapshot file duplication - Easier
maintenance (fewer files to update) - Clearer intent (darwin is the
special case)

**Implementation:**

``` r
# In test files, use conditional variant:
variant = if (system_os() == "darwin") "darwin" else NULL
```

### Alternative Options Considered

#### Option 2: Use Statistical Tolerance Checks

**Replace exact snapshot matching with statistical tests** that check: -
Parameter distributions are similar (K-S test, Wasserstein distance) -
Posterior means within tolerance - Convergence diagnostics (Rhat, ESS)
are acceptable

**Pros:** - Platform-agnostic testing - Focuses on statistical validity,
not bit-exact reproduction - More robust to JAGS version updates

**Cons:** - Harder to detect subtle regressions - Requires defining
appropriate tolerances - May miss important changes

#### Option 3: Keep All OS Variants

Maintain all three OS variants.

**Pros:** - Explicit documentation of platform behavior

**Cons:** - High maintenance burden - Redundant data storage - Confusing
for contributors

## Conclusion

The OS-specific snapshot variants exist because **JAGS MCMC sampling is
inherently platform-dependent due to differences in floating-point
arithmetic, mathematical library implementations, and compiler
optimizations**. However, **Linux and Windows produce identical
results**, making their separate variants redundant.

We adopted Option 1 (consolidate snapshots) to reduce duplication while
maintaining test coverage for the genuine macOS differences.
