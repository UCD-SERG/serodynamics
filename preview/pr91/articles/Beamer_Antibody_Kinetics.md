# Hierarchical Model for Antibody Kinetics: Revisions Based on Advisor Feedback

## Overview

- Incorporates feedback from Dr. Morrison
- Aligns with Teunis et al. (2016, 2023) formulations
- Clarifies model parameter roles and their interpretation
- Assumes block-diagonal covariance structure across biomarkers

## Full Model Structure

**Two-phase within-host antibody kinetics:**

$$\frac{dy}{dt} = \begin{cases}
{\mu_{1}b(t),} & {t < t_{1}} \\
{-\alpha y(t)^{r},} & {t \geq t_{1}}
\end{cases}\quad{\text{with}\mspace{6mu}}\frac{db}{dt} = \mu_{0}b(t) - cy(t)b(t)$$

**Initial conditions:** $y(0) = y_{0}$, $b(0) = b_{0}$  
**Key transition:** $t_{1}$ is the time when
$b\left( t_{1} \right) = 0$  
**Derived quantity:** $y_{1} = y\left( t_{1} \right)$

## Definition of Model Quantities

**Parameters used in the dynamic model:**

- $\mu_{0}$: Pathogen growth rate  
- $\mu_{1}$: Antibody production rate (driven by pathogen)  
- $c$: Clearance rate — how effectively antibodies eliminate pathogen  
- $\alpha$: Antibody decay rate (governs speed of waning)  
- $r$: Shape of antibody decay (nonlinear power)  
- $y_{0}$: Initial antibody concentration at $t = 0$  
- $b_{0}$: Initial pathogen concentration at $t = 0$  
- $y_{1} = y\left( t_{1} \right)$: Peak antibody level — computed at
  time of pathogen clearance

**Note:** Only the first 7 are estimated. $y_{1}$ is derived from the
ODE solution.

## Model Comparison: 2016 vs Our Formulation

| **Component**               | **Teunis (2016)**     | **Our Model**             |
|-----------------------------|-----------------------|---------------------------|
| Pathogen ODE                | $\mu_{0}b(t) - cy(t)$ | $\mu_{0}b(t) - cy(t)b(t)$ |
| Antibody ODE (pre-$t_{1}$)  | $\mu y(t)$            | $\mu_{1}b(t)$             |
| Antibody ODE (post-$t_{1}$) | $-\alpha y(t)^{r}$    | Same                      |
| Antibody growth type        | Exponential           | Pathogen-driven           |
| Antibody rate name          | $\mu$                 | $\mu_{1}$                 |
| $t_{1}$ formula             | Uses $\mu$            | Uses $\mu_{1}$            |

**Note:**

- Antibody production depends on pathogen presence ($b(t)$), not
  constant exponential growth  
- Pathogen clearance is proportional to both antibody and pathogen
  levels ($c\, y(t)\, b(t)$)

## Hierarchical Priors – Subject-Level and Means

**Subject-level parameters:**

$${\mathbf{θ}}_{ij} \sim \mathcal{N}\left( {\mathbf{μ}}_{j},\,\Sigma_{j} \right),\quad{\mathbf{θ}}_{ij} = \begin{bmatrix}
y_{0,ij} \\
b_{0,ij} \\
\mu_{0,ij} \\
\mu_{1,ij} \\
c_{ij} \\
\alpha_{ij} \\
r_{ij}
\end{bmatrix}$$

**Hyperparameters – Means:**

- ${\mathbf{μ}}_{j}$: population-level mean vector for biomarker $j$  
- Prior on ${\mathbf{μ}}_{j}$:

$${\mathbf{μ}}_{j} \sim \mathcal{N}\left( {\mathbf{μ}}_{{hyp},j},\,\Omega_{{hyp},j} \right)$$

- ${\mathbf{μ}}_{{hyp},j}$ and $\Omega_{{hyp},j}$ are fixed or weakly
  informative

## Clarifying Parameter Roles

**Why the confusion about number of parameters?**

- The dynamic model contains 8 named parameters:

$$\mu_{0},\mu_{1},c,\alpha,r,y_{0},b_{0},y_{1}$$

- But only 7 are estimated — the 8th ($y_{1}$) is computed.
- Let’s break this down carefully.

## Classification of Parameters

**Estimated Parameters (7 total):**

- **Core model parameters (5):**

$$\mu_{0},\ \mu_{1},\ c,\ \alpha,\ r$$

- **Initial conditions (2):**

$$y_{0},\ b_{0}$$

**Derived Quantity (not estimated):**

- $y_{1}$: peak antibody level computed as $y\left( t_{1} \right)$

## Time of Pathogen Clearance: $t_{1}$

**Definition:** $t_{1}$ is the time at which the pathogen is cleared,
i.e., $b\left( t_{1} \right) = 0$

**Analytic expression (Teunis et al., 2016):**

$$t_{1} = \frac{1}{\mu_{1} - \mu_{0}}\log\left( 1 + \frac{\left( \mu_{1} - \mu_{0} \right)\, b_{0}}{c\, y_{0}} \right)$$

**Key observations:**

- $t_{1}$ depends on $\mu_{0}$, $\mu_{1}$, $b_{0}$, $y_{0}$, and $c$
- Used to determine $y_{1} = y\left( t_{1} \right)$ by solving the
  antibody ODE up to this point
- Not treated as an estimated parameter — it is computed from model
  inputs

## Why It’s a Seven-Parameter Model

- Our model estimates 7 parameters:
  - **5 core biological parameters:**
    $\mu_{0},\ \mu_{1},\ c,\ \alpha,\ r$
  - **2 initial conditions:** $y_{0},\ b_{0}$
- But we often talk about an eighth quantity, $y_{1}$, the highest level
  of antibody.
- So why isn’t $y_{1}$ counted as a parameter?

## Why $y_{1}$ Is Not Fit Directly

- $y_{1}$ is the antibody level at the time the pathogen is cleared:

$$y_{1} = y\left( t_{1} \right)\quad{\text{where}\mspace{6mu}}b\left( t_{1} \right) = 0$$

- It is not an “input” to the model — we don’t estimate it with MCMC.
- Instead, we **calculate it from the model**:
  - We estimate parameters like $\mu_{1}$, $y_{0}$, $b_{0}$…
  - Then we solve the ODEs to find $t_{1}$ and compute
    $y\left( t_{1} \right)$
- In other words: $y_{1}$ is a **derived output**, not a parameter being
  fit.

## How $y_{1}$ Is Computed

- $y_{1}$ is computed by solving the coupled ODE system:

$$\frac{dy}{dt} = \mu_{1}b(t),\quad\frac{db}{dt} = \mu_{0}b(t) - cy(t)b(t)$$

- The solution is evaluated at $t = t_{1}$ (pathogen clearance point).
- Therefore:

$$y_{1} = y\left( t_{1};\ \mu_{1},\ y_{0},\ b_{0},\ \mu_{0},\ c \right)$$

## Recap: What We Estimate

**Seven model parameters:**

- $\mu_{0},\ \mu_{1},\ c,\ \alpha,\ r$ (biological process)
- $y_{0},\ b_{0}$ (initial state)

**Derived quantity:**

- $y_{1} = y\left( t_{1} \right)$, not directly estimated

## Hierarchical Bayesian Structure

**Individual parameters:**

$$\theta_{ij} = \begin{bmatrix}
y_{0,ij} \\
b_{0,ij} \\
\mu_{0,ij} \\
\mu_{1,ij} \\
c_{ij} \\
\alpha_{ij} \\
r_{ij}
\end{bmatrix} \sim \mathcal{N}\left( \mu_{j},\Sigma_{j} \right)$$

**Hyperparameters:**

- $\mu_{j}$: population-level means (per biomarker $j$)
- $\Sigma_{j}$: $7 \times 7$ covariance matrix over parameters

## Subject-Level Parameters: ${\mathbf{θ}}_{ij}$

$${\mathbf{θ}}_{ij} \sim \mathcal{N}\left( {\mathbf{μ}}_{j},\,\Sigma_{j} \right),\quad{\mathbf{θ}}_{ij} \in {\mathbb{R}}^{7}$$

**Where:**

$${\mathbf{θ}}_{ij} = \begin{bmatrix}
y_{0,ij} \\
b_{0,ij} \\
\mu_{0,ij} \\
\mu_{1,ij} \\
c_{ij} \\
\alpha_{ij} \\
r_{ij}
\end{bmatrix},\quad\Sigma_{j} \in {\mathbb{R}}^{7 \times 7}$$

Each subject $i$ has a unique 7-parameter vector per biomarker $j$,
capturing individual-level variation in dynamics.

## Hyperparameters: Priors on Population Means

**Population-level means:**

$${\mathbf{μ}}_{j} \sim \mathcal{N}\left( {\mathbf{μ}}_{{hyp},j},\Omega_{{hyp},j} \right)$$

**Interpretation:**

- ${\mathbf{μ}}_{j}$: average parameter vector for biomarker $j$
- ${\mathbf{μ}}_{{hyp},j}$: prior guess (e.g., vector of zeros)
- $\Omega_{{hyp},j}$: covariance matrix encoding uncertainty

**Example:**

$${\mathbf{μ}}_{{hyp},j} = 0,\quad\Omega_{{hyp},j} = 100 \cdot I_{7}$$

------------------------------------------------------------------------

## Hyperparameters: Priors on Covariance

**Covariance across parameters:**

$$\Sigma_{j}^{-1} \sim \mathcal{W}\left( \Omega_{j},\nu_{j} \right)$$

- $\Sigma_{j}$: variability/covariance in subject-level parameters
- $\Omega_{j}$: prior scale matrix
- $\nu_{j}$: degrees of freedom

**Example:**

$$\Omega_{j} = 0.1 \cdot I_{7},\quad\nu_{j} = 8$$

------------------------------------------------------------------------

## Measurement Error and Precision Priors

**Observed antibody levels:**

$$\log\left( y_{\text{obs},ij} \right) \sim \mathcal{N}\left( \log\left( y_{\text{pred},ij} \right),\tau_{j}^{-1} \right)$$

**Precision prior:**

$$\tau_{j} \sim \text{Gamma}\left( a_{j},b_{j} \right)$$

- $\tau_{j}$: shared measurement precision for biomarker $j$
- Gamma prior allows flexible noise modeling

------------------------------------------------------------------------

## Matrix Algebra Computation

Let $K = 7$ (parameters), $J$ biomarkers. Then:

$$\Theta_{i} = \begin{bmatrix}
\theta_{i1} & \theta_{i2} & \cdots & \theta_{iJ}
\end{bmatrix} \in {\mathbb{R}}^{K \times J}$$

Assume:

$$\text{vec}\left( \Theta_{i} \right) \sim \mathcal{N}\left( \text{vec}(M),\Sigma_{K} \otimes I_{J} \right)$$

------------------------------------------------------------------------

## Matrix Algebra – Simplified Structure

Setup: $\Theta_{i} \in {\mathbb{R}}^{7 \times J}$

Model:

$$\text{vec}\left( \Theta_{i} \right) \sim \mathcal{N}\left( \text{vec}(M),\Sigma_{K} \otimes I_{J} \right)$$

- $\Sigma_{K}$: 7×7 covariance (same across biomarkers)
- $I_{J}$: biomarkers assumed uncorrelated
- Block-diagonal covariance

------------------------------------------------------------------------

## Understanding $\text{vec}\left( \Theta_{i} \right)$

Each $\theta_{ij} \in {\mathbb{R}}^{7}$:

$$\theta_{ij} = \begin{bmatrix}
y_{0} \\
b_{0} \\
\mu_{0} \\
\mu_{1} \\
c \\
\alpha \\
r
\end{bmatrix}$$

Flattening:

$$\text{vec}\left( \Theta_{i} \right) \in {\mathbb{R}}^{7J \times 1}$$

------------------------------------------------------------------------

## Understanding $\text{vec}(M)$

Let
$M = \left\lbrack \mu_{1}\,\mu_{2}\,\cdots\,\mu_{J} \right\rbrack \in {\mathbb{R}}^{7 \times J}$

Example for $J = 3$:

$$M = \begin{bmatrix}
\mu_{1,1} & \mu_{1,2} & \mu_{1,3} \\
\mu_{2,1} & \mu_{2,2} & \mu_{2,3} \\
\mu_{3,1} & \mu_{3,2} & \mu_{3,3} \\
\mu_{4,1} & \mu_{4,2} & \mu_{4,3} \\
\mu_{5,1} & \mu_{5,2} & \mu_{5,3} \\
\mu_{6,1} & \mu_{6,2} & \mu_{6,3} \\
\mu_{7,1} & \mu_{7,2} & \mu_{7,3}
\end{bmatrix}$$

------------------------------------------------------------------------

## Covariance Structure: $\Sigma_{K} \otimes I_{J}$

$$\text{Cov}\left( \text{vec}\left( \Theta_{i} \right) \right) = \Sigma_{K} \otimes I_{J}$$

- $\Sigma_{K}$: parameter covariance matrix
- $I_{J}$: biomarker-wise independence
- Kronecker product yields block-diagonal matrix

------------------------------------------------------------------------

## Example: Kronecker Product with $K = 2$, $J = 3$

Let:

$$\Sigma_{K} = \begin{bmatrix}
\sigma_{11} & \sigma_{12} \\
\sigma_{21} & \sigma_{22}
\end{bmatrix},\quad I_{3} = \begin{bmatrix}
1 & 0 & 0 \\
0 & 1 & 0 \\
0 & 0 & 1
\end{bmatrix}$$

Then:

$$\Sigma_{K} \otimes I_{3} \in {\mathbb{R}}^{6 \times 6}$$

------------------------------------------------------------------------

## Expanded Matrix: $\Sigma_{K} \otimes I_{3}$

$$\Sigma_{K} \otimes I_{3} = \begin{bmatrix}
\sigma_{11} & 0 & 0 & \sigma_{12} & 0 & 0 \\
0 & \sigma_{11} & 0 & 0 & \sigma_{12} & 0 \\
0 & 0 & \sigma_{11} & 0 & 0 & \sigma_{12} \\
\sigma_{21} & 0 & 0 & \sigma_{22} & 0 & 0 \\
0 & \sigma_{21} & 0 & 0 & \sigma_{22} & 0 \\
0 & 0 & \sigma_{21} & 0 & 0 & \sigma_{22}
\end{bmatrix}$$

------------------------------------------------------------------------

## Next Steps: Modeling Correlation Across Biomarkers

Current Limitation:

- Biomarkers assumed independent: $I_{J}$

Planned Extension:

- Use full covariance $\Sigma_{J}$:

$$\text{Cov}\left( \text{vec}\left( \Theta_{i} \right) \right) = \Sigma_{K} \otimes \Sigma_{J}$$

------------------------------------------------------------------------

## Extending to Correlated Biomarkers

Assume $K = 3$, $J = 3$

Define:

$$\Sigma_{K} = \begin{bmatrix}
\sigma_{11} & \sigma_{12} & \sigma_{13} \\
\sigma_{21} & \sigma_{22} & \sigma_{23} \\
\sigma_{31} & \sigma_{32} & \sigma_{33}
\end{bmatrix},\quad\Sigma_{J} = \begin{bmatrix}
\tau_{11} & \tau_{12} & \tau_{13} \\
\tau_{21} & \tau_{22} & \tau_{23} \\
\tau_{31} & \tau_{32} & \tau_{33}
\end{bmatrix}$$

------------------------------------------------------------------------

## Kronecker Product Structure: $\Sigma_{K} \otimes \Sigma_{J}$

$$\Sigma_{K} \otimes \Sigma_{J} = \begin{bmatrix}
{\sigma_{11}\Sigma_{J}} & {\sigma_{12}\Sigma_{J}} & {\sigma_{13}\Sigma_{J}} \\
{\sigma_{21}\Sigma_{J}} & {\sigma_{22}\Sigma_{J}} & {\sigma_{23}\Sigma_{J}} \\
{\sigma_{31}\Sigma_{J}} & {\sigma_{32}\Sigma_{J}} & {\sigma_{33}\Sigma_{J}}
\end{bmatrix}$$

Now biomarkers and parameters can be correlated.

------------------------------------------------------------------------

## Expanded Form: $\Sigma_{K} \otimes \Sigma_{J}$ (3x3)

The $9 \times 9$ matrix contains all combinations $\sigma_{ab}\tau_{cd}$

Not block-diagonal — includes cross-biomarker correlation

------------------------------------------------------------------------

## Practical To-Do List (for Chapter 2)

**Model Implementation:**

- Define full $\Sigma_{J}$ and prior:
  $\Sigma_{J}^{-1} \sim \mathcal{W}(\Psi,\nu)$  
- Implement $\Sigma_{K} \otimes \Sigma_{J}$ in JAGS

**Simulation + Validation:**

- Simulate individuals with correlated biomarkers  
- Fit both block-diagonal and full-covariance models  
- Compare fit: DIC, WAIC, predictive checks
