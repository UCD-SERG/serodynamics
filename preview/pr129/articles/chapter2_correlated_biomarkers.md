# Modeling Correlation in Antibody Kinetics: A Hierarchical Bayesian Approach

## Overview

- Incorporates feedback from Dr. Morrison and Dr. Aiemjoy  
- Builds on ([Teunis and Eijkeren 2016](#ref-teunis2016)) framework for
  antibody kinetics  
- Focus on covariance structure: parameter covariance within each
  biomarker ($\Sigma_{P,j}$, 5×5 per biomarker) and biomarker covariance
  across $j$ ($\Sigma_{B}$, across biomarkers)  
- Uses updated parameterization: $\log\left( y_{0} \right)$,
  $\log\left( y_{1} - y_{0} \right)$, $\log\left( t_{1} \right)$,
  $\log(\alpha)$, $\log(\rho - 1)$  
- Current stage: block-diagonal covariance (independent biomarkers)  
- Planned extension: full $\Sigma_{B}$ to capture correlation between
  biomarkers

------------------------------------------------------------------------

## Observation Model (Data Level)

Observed (log-transformed) antibody levels:

$$\log\left( y_{\text{obs},ij} \right) \sim \mathcal{N}\left( \mu_{\log y,ij},\tau_{j}^{-1} \right)\qquad(1)$$

Where:

- $y_{\text{obs},ij}$: Observed antibody level for subject $i$ and
  biomarker $j$
- $\mu_{\log y,ij}$ is the **expected log antibody level**, computed
  from the two-phase model using subject-level parameters $\theta_{ij}$.
- $\theta_{ij}$: Subject-level latent parameters (e.g.,
  $y_{0},\alpha,\rho$) used to define the predicted antibody curve
- $\tau_{j}$: Measurement precision (inverse of variance) specific to
  biomarker $j$

Measurement precision prior:

$$\tau_{j} \sim \text{Gamma}\left( a_{j},b_{j} \right)\qquad(2)$$

Where:

- $\tau_{j}$: Precision (inverse of variance) of the measurement noise
  for biomarker $j$
- $\left( a_{j},b_{j} \right)$: Shape and rate hyperparameters of the
  Gamma prior for precision, which control its expected value and
  variability

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

## Within-Host ODE System ([Teunis and Eijkeren 2016](#ref-teunis2016))

**Two-phase within-host antibody kinetics:**

$$\frac{dy}{dt} = \begin{cases}
{\mu_{y}y(t),} & {t \leq t_{1}} \\
{-\alpha y(t)^{\rho},} & {t > t_{1}}
\end{cases}\quad{\text{with}\mspace{6mu}}\frac{db}{dt} = \mu_{b}b(t) - \gamma y(t)\qquad(3)$$

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

$$t_{1} = \frac{1}{\mu_{y} - \mu_{b}}\log\left( 1 + \frac{\left( \mu_{y} - \mu_{b} \right)b_{0}}{\gamma y_{0}} \right)\qquad(4)$$

**Peak Antibody Level** $y_{1}$

$$y_{1} = y_{0}e^{\mu_{y}t_{1}}\qquad(5)$$

------------------------------------------------------------------------

## Model Comparison: ([Teunis and Eijkeren 2016](#ref-teunis2016)) vs serodynamics

| Component                   | ([Teunis and Eijkeren 2016](#ref-teunis2016)) | serodynamics                    |
|-----------------------------|-----------------------------------------------|---------------------------------|
| Pathogen ODE                | $\mu_{0}b(t) - cy(t)$                         | $\mu_{b}b(t) - \gamma y(t)$     |
| Antibody ODE (pre-$t_{1}$)  | $\mu y(t)$                                    | $\mu_{y}y(t)$                   |
| Antibody ODE (post-$t_{1}$) | $-\alpha y(t)^{r}$                            | $-\alpha y(t)^{\rho}$           |
| Antibody growth type        | Pathogen-driven                               | Self-driven exponential         |
| Antibody rate name          | $\mu$                                         | $\mu_{y}$                       |
| $t_{1}$ formula             | Uses $\mu_{0}$, $\mu$, $b_{0}$, $c$, $y_{0}$  | Uses $\mu_{b}$, $\mu_{y}$, etc. |

Table 2: Comparison of Teunis (2016) model and serodynamic’s model
assumptions.

**Note:**

- ([Teunis and Eijkeren 2016](#ref-teunis2016)) uses **linear
  clearance**: $cy(t)$, not bilinear  
- Antibody production is **driven by pathogen** $b(t)$  
- Our model simplifies by assuming self-expanding antibody dynamics

------------------------------------------------------------------------

## Full Parameter Model (7 Parameters)

**Subject-level parameters:**

$$\theta_{ij} \sim \mathcal{N}\left( \mu_{j},\,\Sigma_{P,j} \right),\quad\theta_{ij} = \begin{bmatrix}
y_{0,ij} \\
b_{0,ij} \\
\mu_{b,ij} \\
\mu_{y,ij} \\
\gamma_{ij} \\
\alpha_{ij} \\
\rho_{ij}
\end{bmatrix}$$**Where:**

- $\theta_{ij}$: parameter vector for subject $i$, biomarker $j$  
- $\mu_{j}$: population-level mean vector for biomarker $j$  
- $\Sigma_{P,j} \in {\mathbb{R}}^{7 \times 7}$: covariance matrix
  **across parameters** for biomarker $j$
  - Subscript $P$: denotes that this is covariance over the **P
    parameters**  
  - Subscript $j$: indicates the biomarker index

**Hyperparameters – Means:**

$$\mu_{j} \sim \mathcal{N}\left( \mu_{\text{hyp},j},\,\Omega_{\text{hyp},j} \right)$$

------------------------------------------------------------------------

## From Full 7 Parameters to 5 Latent Parameters

- Although the model estimates 7 parameters, for modeling antibody
  kinetics $y(t)$, we focus on **5-parameter subset**:

$$y_{0},\ \ t_{1}\left( \text{derived} \right),\ \ y_{1}\left( \text{derived} \right),\ \ \alpha,\ \ \rho$$

- These 5 parameters are **log-transformed** into the latent parameters
  $\theta\_{ij}$ used for modeling.

------------------------------------------------------------------------

## 5 Core Parameters Used for Curve Drawing

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

## Subject-Level Parameters (Latent Version = serodynamics)

Each subject $i$ and biomarker $j$ has latent parameters:

$$\theta_{ij} = \begin{bmatrix}
{\log\left( y_{0,ij} \right)} \\
{\log\left( y_{1,ij} - y_{0,ij} \right)} \\
{\log\left( t_{1,ij} \right)} \\
{\log\left( \alpha_{ij} \right)} \\
{\log\left( \rho_{ij} - 1 \right)}
\end{bmatrix} \in {\mathbb{R}}^{5}\qquad(6)$$

Distribution:

$$\theta_{ij} \sim \mathcal{N}\left( \mu_{j},\Sigma_{P,j} \right)$$**Where:**

- $\mu_{j}$: population-level mean vector for biomarker $j$  
- $\Sigma_{P,j} \in {\mathbb{R}}^{5 \times 5}$: covariance matrix
  **across the** $P = 5$ parameters for biomarker $j$

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

## Hierarchical Bayesian Structure (serodynamics)

**Individual parameters:**

$$\theta_{ij} = \begin{bmatrix}
{\log\left( y_{0,ij} \right)} \\
{\log\left( y_{1,ij} - y_{0,ij} \right)} \\
{\log\left( t_{1,ij} \right)} \\
{\log\left( \alpha_{ij} \right)} \\
{\log\left( \rho_{ij} - 1 \right)}
\end{bmatrix} \sim \mathcal{N}\left( \mu_{j},\,\Sigma_{P,j} \right)$$

**Hyperparameters:**

- $\mu_{j}$: population-level mean vector for biomarker $j$  
- $\Sigma_{P,j} \in {\mathbb{R}}^{P \times P},\; P = 5$: covariance
  matrix **across the parameters** for biomarker $j$

------------------------------------------------------------------------

## Subject-Level Parameters: $\theta_{ij}$

$$\theta_{ij} \sim \mathcal{N}\left( \mu_{j},\,\Sigma_{P,j} \right),\quad\theta_{ij} \in {\mathbb{R}}^{5}$$

**Where:**

$${\mathbf{θ}}_{ij} = \begin{bmatrix}
{\log\left( y_{0,ij} \right)} \\
{\log\left( y_{1,ij} - y_{0,ij} \right)} \\
{\log\left( t_{1,ij} \right)} \\
{\log\left( \alpha_{ij} \right)} \\
{\log\left( \rho_{ij} - 1 \right)}
\end{bmatrix},\quad\Sigma_{P,j} \in {\mathbb{R}}^{P \times P},\; P = 5$$

Each subject $i$ has a unique 5-parameter vector per biomarker $j$,
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

$${\mathbf{μ}}_{{hyp},j} = 0,\quad\Omega_{{hyp},j} = 100 \cdot I_{5}$$

------------------------------------------------------------------------

## Hyperparameters: Priors on Covariance

**Covariance across parameters:**

$$\Sigma_{P,j}^{-1} \sim \mathcal{W}\left( \Omega_{j},\nu_{j} \right)$$

- $\Sigma_{P,j}$: $5 \times 5$ covariance matrix of subject-level
  parameters for biomarker $j$  
- $\Omega_{j}$: prior scale matrix (dimension $5 \times 5$)  
- $\nu_{j}$: degrees of freedom

**Example:**

$$\Omega_{j} = 0.1 \cdot I_{5},\quad\nu_{j} = 6$$

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

Let $P = 5$ (parameters), $B$ biomarkers. Then:

$$\Theta_{i} = \begin{bmatrix}
\theta_{i1} & \theta_{i2} & \cdots & \theta_{iB}
\end{bmatrix} \in {\mathbb{R}}^{P \times B}$$

Assume:

$$\text{vec}\left( \Theta_{i} \right) \sim \mathcal{N}\left( \text{vec}(M),\Sigma_{P} \otimes I_{B} \right)$$

------------------------------------------------------------------------

## Matrix Algebra – Simplified Structure

Setup: $\Theta_{i} \in {\mathbb{R}}^{P \times B}$

Model:

$$\text{vec}\left( \Theta_{i} \right) \sim \mathcal{N}\left( \text{vec}(M),\Sigma_{P} \otimes I_{B} \right)$$

- $\Sigma_{P}$: 5×5 covariance (same across biomarkers)
- $I_{B}$: biomarkers assumed uncorrelated
- Block-diagonal covariance

------------------------------------------------------------------------

## Understanding $\text{vec}\left( \Theta_{i} \right)$

Each $\theta_{ij} \in {\mathbb{R}}^{5}$:

$$\theta_{ij} = \begin{bmatrix}
{\log\left( y_{0,ij} \right)} \\
{\log\left( y_{1,ij} - y_{0,ij} \right)} \\
{\log\left( t_{1,ij} \right)} \\
{\log\left( \alpha_{ij} \right)} \\
{\log\left( \rho_{ij} - 1 \right)}
\end{bmatrix}$$

Flattening:

$$\text{vec}\left( \Theta_{i} \right) \in {\mathbb{R}}^{5B \times 1}$$

------------------------------------------------------------------------

## Understanding $\text{vec}(M)$

Let
$M = \left\lbrack \mu_{1}\,\mu_{2}\,\cdots\,\mu_{B} \right\rbrack \in {\mathbb{R}}^{5 \times B}$

Example for $B = 3$:

$$M = \begin{bmatrix}
\mu_{1,1} & \mu_{1,2} & \mu_{1,3} \\
\mu_{2,1} & \mu_{2,2} & \mu_{2,3} \\
\mu_{3,1} & \mu_{3,2} & \mu_{3,3} \\
\mu_{4,1} & \mu_{4,2} & \mu_{4,3} \\
\mu_{5,1} & \mu_{5,2} & \mu_{5,3}
\end{bmatrix}$$

------------------------------------------------------------------------

## Covariance Structure: $\Sigma_{P} \otimes I_{B}$

$$\text{Cov}\left( \text{vec}\left( \Theta_{i} \right) \right) = \Sigma_{P} \otimes I_{B}$$

- $\Sigma_{P}$: parameter covariance matrix
- $I_{B}$: biomarker-wise independence
- Kronecker product yields block-diagonal matrix

------------------------------------------------------------------------

## Example: Kronecker Product with $P = 5$, $B = 3$

Let:

$$\Sigma_{P} = \begin{bmatrix}
\sigma_{y_{0},y_{0}} & \sigma_{y_{0},y_{1} - y_{0}} & \sigma_{y_{0},t_{1}} & \sigma_{y_{0},\alpha} & \sigma_{y_{0},\rho - 1} \\
\sigma_{y_{1} - y_{0},y_{0}} & \sigma_{y_{1} - y_{0},y_{1} - y_{0}} & \sigma_{y_{1} - y_{0},t_{1}} & \sigma_{y_{1} - y_{0},\alpha} & \sigma_{y_{1} - y_{0},\rho - 1} \\
\sigma_{t_{1},y_{0}} & \sigma_{t_{1},y_{1} - y_{0}} & \sigma_{t_{1},t_{1}} & \sigma_{t_{1},\alpha} & \sigma_{t_{1},\rho - 1} \\
\sigma_{\alpha,y_{0}} & \sigma_{\alpha,y_{1} - y_{0}} & \sigma_{\alpha,t_{1}} & \sigma_{\alpha,\alpha} & \sigma_{\alpha,\rho - 1} \\
\sigma_{\rho - 1,y_{0}} & \sigma_{\rho - 1,y_{1} - y_{0}} & \sigma_{\rho - 1,t_{1}} & \sigma_{\rho - 1,\alpha} & \sigma_{\rho - 1,\rho - 1}
\end{bmatrix},\quad I_{B} = \begin{bmatrix}
1 & 0 & 0 \\
0 & 1 & 0 \\
0 & 0 & 1
\end{bmatrix}$$

Then:

$$\Sigma_{P} \otimes I_{B} \in {\mathbb{R}}^{15 \times 15}$$

------------------------------------------------------------------------

## Expanded Matrix: $\Sigma_{P} \otimes I_{B}$

$$\Sigma_{P} \otimes I_{B} = \begin{bmatrix}
\Sigma_{P} & 0 & 0 \\
0 & \Sigma_{P} & 0 \\
0 & 0 & \Sigma_{P}
\end{bmatrix} \in {\mathbb{R}}^{15 \times 15}$$

where each block $\Sigma_{P}$ is the $5 \times 5$ covariance across
parameters:

$$\Sigma_{P} = \begin{bmatrix}
\sigma_{y_{0},y_{0}} & \cdots & \sigma_{y_{0},\rho - 1} \\
\vdots & \ddots & \vdots \\
\sigma_{\rho - 1,y_{0}} & \cdots & \sigma_{\rho - 1,\rho - 1}
\end{bmatrix}$$

------------------------------------------------------------------------

## Next Steps: Modeling Correlation Across Biomarkers

Current Limitation:

- Biomarkers assumed independent: $I_{B}$

Planned Extension:

- Use full covariance $\Sigma_{B}$:

$$\text{Cov}\left( \text{vec}\left( \Theta_{i} \right) \right) = \Sigma_{P} \otimes \Sigma_{B}$$

------------------------------------------------------------------------

## Extending to Correlated Biomarkers

Assume $P = 5$, $B = 3$

Define:

$$\Sigma_{P} = \begin{bmatrix}
\sigma_{y_{0},y_{0}} & \sigma_{y_{0},y_{1} - y_{0}} & \sigma_{y_{0},t_{1}} & \sigma_{y_{0},\alpha} & \sigma_{y_{0},\rho - 1} \\
\sigma_{y_{1} - y_{0},y_{0}} & \sigma_{y_{1} - y_{0},y_{1} - y_{0}} & \sigma_{y_{1} - y_{0},t_{1}} & \sigma_{y_{1} - y_{0},\alpha} & \sigma_{y_{1} - y_{0},\rho - 1} \\
\sigma_{t_{1},y_{0}} & \sigma_{t_{1},y_{1} - y_{0}} & \sigma_{t_{1},t_{1}} & \sigma_{t_{1},\alpha} & \sigma_{t_{1},\rho - 1} \\
\sigma_{\alpha,y_{0}} & \sigma_{\alpha,y_{1} - y_{0}} & \sigma_{\alpha,t_{1}} & \sigma_{\alpha,\alpha} & \sigma_{\alpha,\rho - 1} \\
\sigma_{\rho - 1,y_{0}} & \sigma_{\rho - 1,y_{1} - y_{0}} & \sigma_{\rho - 1,t_{1}} & \sigma_{\rho - 1,\alpha} & \sigma_{\rho - 1,\rho - 1}
\end{bmatrix},\quad\Sigma_{B} = \begin{bmatrix}
\tau_{11} & \tau_{12} & \tau_{13} \\
\tau_{21} & \tau_{22} & \tau_{23} \\
\tau_{31} & \tau_{32} & \tau_{33}
\end{bmatrix}$$

Here:

- $\Sigma_{P}$: covariance across the 5 parameters (size $5 \times 5$)  
- $\Sigma_{B}$: covariance across the $B$ biomarkers (size $B \times B$)

------------------------------------------------------------------------

## Kronecker Product Structure: $\Sigma_{P} \otimes \Sigma_{B}$

$$\text{Cov}\left( \text{vec}\left( \Theta_{i} \right) \right) = \Sigma_{P} \otimes \Sigma_{B}$$

- $\Sigma_{P}$: $5 \times 5$ covariance across parameters  
- $\Sigma_{B}$: $B \times B$ covariance across biomarkers  
- The Kronecker product expands to a $(5B) \times (5B)$ covariance
  matrix  
- Not block-diagonal — allows both parameter correlations *and*
  cross-biomarker correlations

------------------------------------------------------------------------

## Practical To-Do List (for Chapter 2)

**Model Implementation:**

- Define parameter covariance $\Sigma_{P,j}$ (within each biomarker
  $j$)  
- Define biomarker covariance $\Sigma_{B}$ (across biomarkers)  
- Full covariance structure:
  $\text{Cov}\left( \text{vec}\left( \theta_{i} \right) \right) = \Sigma_{P} \otimes \Sigma_{B}$  
- Priors:
  $\Sigma_{P,j}^{-1} \sim \mathcal{W}\left( \Omega_{j},\nu_{j} \right)$,
  $\Sigma_{B}^{-1} \sim \mathcal{W}\left( \Omega_{B},\nu_{B} \right)$

**Simulation Study (first step):**

- Generate fake longitudinal data with known $\Sigma_{P}$ and
  $\Sigma_{B}$  
- Fit independence model ($I_{B}$) vs. correlated model ($\Sigma_{B}$)  
- Evaluate recovery of true covariance structure

**Validation on Real Data (next step):**

- Apply to Shigella longitudinal data  
- Compare independence vs. correlated models (DIC, WAIC, posterior
  predictive checks)  
- Summarize implications for epidemiologic utility

**Deliverable:**

- Simulation + model comparison documented in a vignette for the
  serodynamics package

Teunis, Peter F. M., and J. C. H. van Eijkeren. 2016. “Linking the
Seroresponse to Infection to Within-Host Heterogeneity in Antibody
Production.” *Epidemics* 16: 33–39.
<https://doi.org/10.1016/j.epidem.2016.04.001>.
