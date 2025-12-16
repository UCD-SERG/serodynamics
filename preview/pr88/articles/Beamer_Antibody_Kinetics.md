# Extending the Hierarchical Model for Antibody Kinetics

## Overview

- Incorporates feedback from Dr. Morrison and Dr.Aiemjoy
- Focus exclusively on ([Teunis and Eijkeren 2016](#ref-teunis2016))
  model
- Clarifies model dynamics: growth, clearance, decay
- Uses updated parameter notation: $\mu_{y}$, $\mu_{b}$, $\gamma$,
  $\alpha$, $\rho$
- Assumes block-diagonal covariance structure across biomarkers

------------------------------------------------------------------------

## Within-Host ODE System ([Teunis and Eijkeren 2016](#ref-teunis2016))

**Two-phase within-host antibody kinetics:**

$$\frac{dy}{dt} = \begin{cases}
{\mu_{y}y(t),} & {t \leq t_{1}} \\
{-\alpha y(t)^{\rho},} & {t > t_{1}}
\end{cases}\quad{\text{with}\mspace{6mu}}\frac{db}{dt} = \mu_{b}b(t) - \gamma y(t)\qquad(1)$$

**Initial conditions:** $y(0) = y_{0}$, $b(0) = b_{0}$  
**Key transition:** $t_{1}$ is the time when
$b\left( t_{1} \right) = 0$  
**Derived quantity:** $y_{1} = y\left( t_{1} \right)$

------------------------------------------------------------------------

## Closed-Form Solutions

**Antibody concentration** $y(t)$

- $t \leq t_{1}$:  
  $$y(t) = y_{0}e^{\mu_{y}t}$$

- $t > t_{1}$:  
  $$y(t) = y_{1}\left( 1 + (\rho - 1)\alpha y_{1}^{\rho - 1}\left( t - t_{1} \right) \right)^{-\frac{1}{\rho - 1}}$$

**Pathogen load** $b(t)$

- $t \leq t_{1}$:  
  $$b(t) = b_{0}e^{\mu_{b}t} - \frac{\gamma y_{0}}{\mu_{y} - \mu_{b}}\left( e^{\mu_{y}t} - e^{\mu_{b}t} \right)$$

- $t > t_{1}$:  
  $$b(t) = 0$$

------------------------------------------------------------------------

## Time of Peak Response

**Peak Time** $t_{1}$

$$t_{1} = \frac{1}{\mu_{y} - \mu_{b}}\log\left( 1 + \frac{\left( \mu_{y} - \mu_{b} \right)b_{0}}{\gamma y_{0}} \right)\qquad(2)$$

**Peak Antibody Level** $y_{1}$

$$y_{1} = y_{0}e^{\mu_{y}t_{1}}\qquad(3)$$

------------------------------------------------------------------------

## Parameter Summary

| Symbol    | Description                             |
|-----------|-----------------------------------------|
| $\mu_{y}$ | Antibody production rate (growth phase) |
| $\mu_{b}$ | Pathogen replication rate               |
| $\gamma$  | Clearance rate (by antibodies)          |
| $\alpha$  | Antibody decay rate                     |
| $\rho$    | Shape of antibody decay (power-law)     |
| $t_{1}$   | Time of peak response                   |
| $y_{1}$   | Peak antibody concentration             |

Table 1: Parameter summary for antibody kinetics model.

**Note:** Only the first 6 are typically estimated. $y_{1}$ is derived
from the ODE solution at $t_{1}$.

------------------------------------------------------------------------

## Model Comparison: ([Teunis and Eijkeren 2016](#ref-teunis2016)) vs This Presentation

| Component                   | ([Teunis and Eijkeren 2016](#ref-teunis2016)) | This Presentation               |
|-----------------------------|-----------------------------------------------|---------------------------------|
| Pathogen ODE                | $\mu_{0}b(t) - cy(t)$                         | $\mu_{b}b(t) - \gamma y(t)$     |
| Antibody ODE (pre-$t_{1}$)  | $\mu y(t)$                                    | $\mu_{y}y(t)$                   |
| Antibody ODE (post-$t_{1}$) | $-\alpha y(t)^{r}$                            | $-\alpha y(t)^{\rho}$           |
| Antibody growth type        | Pathogen-driven                               | Self-driven exponential         |
| Antibody rate name          | $\mu$                                         | $\mu_{y}$                       |
| $t_{1}$ formula             | Uses $\mu_{0}$, $\mu$, $b_{0}$, $c$, $y_{0}$  | Uses $\mu_{b}$, $\mu_{y}$, etc. |

Table 2: Comparison of Teunis (2016) model and this presentation’s model
assumptions.

**Note:**

- ([Teunis and Eijkeren 2016](#ref-teunis2016)) uses **linear
  clearance**: $cy(t)$, not bilinear  
- Antibody production is **driven by pathogen** $b(t)$  
- Our model simplifies by assuming self-expanding antibody dynamics

------------------------------------------------------------------------

## Full Parameter Model (7 Parameters)

**Subject-level parameters:**

$$\theta_{ij} \sim \mathcal{N}\left( \mu_{j},\,\Sigma_{j} \right),\quad\theta_{ij} = \begin{bmatrix}
y_{0,ij} \\
b_{0,ij} \\
\mu_{b,ij} \\
\mu_{y,ij} \\
\gamma_{ij} \\
\alpha_{ij} \\
\rho_{ij}
\end{bmatrix}$$

**Hyperparameters – Means:**

- $\mu_{j}$: population-level mean vector for biomarker $j$
- Prior on $\mu_{j}$:

$$\mu_{j} \sim \mathcal{N}\left( \mu_{\text{hyp},j},\,\Omega_{\text{hyp},j} \right)$$

------------------------------------------------------------------------

## Core Parameters Used for Curve Drawing

In this presentation, we focus on **5 key parameters** required to draw
antibody curves:

- $y_{0}$: initial antibody level
- $t_{1}$: time of peak antibody response
- $y_{1}$: peak antibody level
- $\alpha$: decay rate
- $\rho$: shape of decay

Note: $t_{1}$ and $y_{1}$ are **derived from the full model** - These 5
are sufficient for prediction and plotting

------------------------------------------------------------------------

## Classifying Model Parameters (([Teunis and Eijkeren 2016](#ref-teunis2016)) Structure)

**Estimated Parameters (7 total):**

- **Core model parameters (5):** $\mu_{b}$, $\mu_{y}$, $\gamma$,
  $\alpha$, $\rho$

- **Initial conditions (2):** $y_{0}$, $b_{0}$

**Derived Quantity (not estimated):**

- $y_{1}$: peak antibody level computed as $y\left( t_{1} \right)$

------------------------------------------------------------------------

## Time of Pathogen Clearance $t_{1}$

**Definition:** $t_{1}$ is the time when the pathogen is cleared, i.e.,
$b\left( t_{1} \right) = 0$

**Analytic expression:**

$$t_{1} = \frac{1}{\mu_{y} - \mu_{b}}\log\left( 1 + \frac{\left( \mu_{y} - \mu_{b} \right)b_{0}}{\gamma y_{0}} \right)$$

**Key observations:** $t_{1}$ depends on $\mu_{b}$, $\mu_{y}$, $b_{0}$,
$y_{0}$, and $y_{1} = y\left( t_{1} \right)$ is computed based on this
time point

------------------------------------------------------------------------

## Why It’s a Seven-Parameter Model

- Our model estimates **7 parameters**:
  - 5 biological parameters: $\mu_{b}$, $\mu_{y}$, $\gamma$, $\alpha$,
    $\rho$
  - 2 initial conditions: $y_{0}$, $b_{0}$
- But we often refer to an 8th quantity: $y_{1}$
- So why isn’t $y_{1}$ a parameter?

*Answer*: $y_{1}$ is a **computed value**, not directly estimated.

------------------------------------------------------------------------

## Why $y_{1}$ Is Not Fit Directly

- $y_{1}$ is the antibody level at the time the pathogen is cleared:

$$y_{1} = y\left( t_{1} \right)\quad{\text{where}\mspace{6mu}}b\left( t_{1} \right) = 0$$

- $y_{1}$ is not an “input” — it is **computed** from:
  - $\mu_{y}$, $y_{0}$, $b_{0}$, $\mu_{b}$, $\gamma$
  - via solution of ODEs to find $t_{1}$ and compute
    $y\left( t_{1} \right)$

In other words: $y_{1}$ is a **derived output**, not a fit parameter.

------------------------------------------------------------------------

## How $y_{1}$ Is Computed

- $y_{1}$ is computed by solving the ODE system:

$$\frac{dy}{dt} = \mu_{y}y(t),\quad\frac{db}{dt} = \mu_{b}b(t) - \gamma y(t)$$

- Evaluate $y(t)$ at $t = t_{1}$ using ODE solution:

$$y_{1} = y\left( t_{1};\mu_{y},y_{0},b_{0},\mu_{b},\gamma \right)$$

------------------------------------------------------------------------

## Recap: What We Estimate

**Seven model parameters (***7-parameter model for full dynamics***):**

- $\mu_{b}$, $\mu_{y}$, $\gamma$, $\alpha$, $\rho$ (biological process)
- $y_{0}$, $b_{0}$ (initial state)

**Derived quantity:**

- $y_{1} = y\left( t_{1} \right)$ — not directly estimated, computed

**5-parameter subset for curve visualization:**

- $y_{0}$, $y_{1}$, $t_{1}$, $\alpha$, $\rho$

------------------------------------------------------------------------

## Hierarchical Bayesian Structure

**Individual parameters:**

$$\theta_{ij} = \begin{bmatrix}
y_{0,ij} \\
b_{0,ij} \\
\mu_{b,ij} \\
\mu_{y,ij} \\
\gamma_{ij} \\
\alpha_{ij} \\
\rho_{ij}
\end{bmatrix} \sim \mathcal{N}\left( \mu_{j},\,\Sigma_{j} \right)$$

**Hyperparameters:**

- $\mu_{j}$: population-level means (per biomarker $j$)
- $\Sigma_{j}$: $7 \times 7$ covariance matrix over parameters

------------------------------------------------------------------------

## Subject-Level Parameters: $\theta_{ij}$

$$\theta_{ij} \sim \mathcal{N}\left( \mu_{j},\,\Sigma_{j} \right),\quad\theta_{ij} \in {\mathbb{R}}^{7}$$

**Where:**

$${\mathbf{θ}}_{ij} = \begin{bmatrix}
y_{0,ij} \\
b_{0,ij} \\
\mu_{b,ij} \\
\mu_{y,ij} \\
\gamma_{ij} \\
\alpha_{ij} \\
\rho_{ij}
\end{bmatrix},\quad\Sigma_{j} \in {\mathbb{R}}^{7 \times 7}$$

Each subject $i$ has a unique 7-parameter vector per biomarker $j$,
capturing individual-level variation in antibody dynamics.

------------------------------------------------------------------------

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

Teunis, Peter F. M., and J. C. H. van Eijkeren. 2016. “Linking the
Seroresponse to Infection to Within-Host Heterogeneity in Antibody
Production.” *Epidemics* 16: 33–39.
<https://doi.org/10.1016/j.epidem.2016.04.001>.
