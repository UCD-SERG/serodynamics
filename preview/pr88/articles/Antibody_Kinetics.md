# Hierarchical Bayesian Modeling of Antibody Kinetics: Extensions and Refinements

## Overview

- Incorporates feedback from Dr. Morrison, Dr. Aiemjoy, and lab
  discussion
- Focus exclusively on ([Teunis and Eijkeren 2016](#ref-teunis2016))
  two-phase within-host model
- Clarifies full hierarchical Bayesian modeling structure
- Explicitly distinguishes between priors, hyperpriors, transformations
- Reorders: **Start from observation model → build upward**

------------------------------------------------------------------------

## Big Picture: What Are We Modeling?

We are modeling **how antibody levels change over time** in response to
infection, using multiple individuals and multiple biomarkers
(antigen-isotype combinations, (j = 1, 2, $\ldots$, 10)).

Goals:

- Understand the **average pattern** for each biomarker
- Allow for **individual-level variation**
- **Share information** across individuals to improve inference

This motivates using a **hierarchical Bayesian model**.

------------------------------------------------------------------------

## Step 1: Observation Model (Data Level)

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

The expression above corresponds to line 54 of `model.jags`:

``` numberSource
     logy[subj,obs,cur_antigen_iso] ~ dnorm(mu.logy[subj,obs,cur_antigen_iso], prec.logy[cur_antigen_iso])
```

Measurement precision prior:

$$\tau_{j} \sim \text{Gamma}\left( a_{j},b_{j} \right)\qquad(2)$$

Where:

- $\tau_{j}$: Precision (inverse of variance) of the measurement noise
  for biomarker $j$
- $\left( a_{j},b_{j} \right)$: Shape and rate hyperparameters of the
  Gamma prior for precision, which control its expected value and
  variability

The expression above corresponds to line 75 of `model.jags`:

``` numberSource
  prec.logy[cur_antigen_iso] ~ dgamma(prec.logy.hyp[cur_antigen_iso,1], prec.logy.hyp[cur_antigen_iso,2])
```

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

## Step 2: Within-Host ODE System ([Teunis and Eijkeren 2016](#ref-teunis2016))

$$\frac{dy}{dt} = \begin{cases}
{\mu_{y}y(t),} & {t \leq t_{1}} \\
{-\alpha y(t)^{\rho},} & {t > t_{1}}
\end{cases}\quad\text{and}\quad\frac{db}{dt} = \mu_{b}b(t) - \gamma y(t)\qquad(3)$$

- Initial conditions: $y(0) = y_{0}$, $b(0) = b_{0}$
- Transition at $t_{1}$: when $b\left( t_{1} \right) = 0$

------------------------------------------------------------------------

## Step 3: Closed-Form Solutions

**Antibody concentration:**

- For $t \leq t_{1}$: $$y(t) = y_{0}e^{\mu_{y}t}\qquad(4)$$
- For $t\ t_{1}$:
  $$y(t) = y_{1}\left( 1 + (\rho - 1)\alpha y_{1}^{\rho - 1}\left( t - t_{1} \right) \right)^{-\frac{1}{\rho - 1}}\qquad(5)$$

The expression above corresponds to lines 18-50 of `model.jags`:

``` numberSource
     mu.logy[subj, obs, cur_antigen_iso] <- ifelse(
        
        # `step(x)` returns 1 if x >= 0;
        # here we are determining which phase of infection we are in; 
        # active or recovery;
        # `smpl.t` is the time when the blood sample was collected, 
        # relative to estimated start of infection;
        # so we are determining whether the current observation is after `t1` 
        # the time when the active infection ended.
        step(t1[subj,cur_antigen_iso] - smpl.t[subj,obs]), 
        
        ## active infection period:
        # this is equation 15, case t <= t_1, but on a logarithmic scale
        log(y0[subj,cur_antigen_iso]) + (beta[subj,cur_antigen_iso] * smpl.t[subj,obs]),
        
        ## recovery period:
        # this is equation 15, case t > t_1
        1 / (1 - shape[subj,cur_antigen_iso]) *
           log(
              # this is `log{y_1^(1-r)}`; 
              # the exponent cancels out with the factor outside the log
              y1[subj, cur_antigen_iso]^(1 - shape[subj, cur_antigen_iso]) - 
                 
               # this is (1-r); not sure why switched from paper  
              (1 - shape[subj,cur_antigen_iso]) *
                
                  # (there's no missing y1^(r-1) term here; the math checks out)
                 
                 # alpha is `nu` in Teunis 2016; the "decay rate" parameter
                alpha[subj,cur_antigen_iso] *
                 
                 # this is `t - t_1`
                 (smpl.t[subj,obs] - t1[subj,cur_antigen_iso])))
```

**Pathogen load:**

- For $t \leq t_{1}$:
  $$b(t) = b_{0}e^{\mu_{b}t} - \frac{\gamma y_{0}}{\mu_{y} - \mu_{b}}\left( e^{\mu_{y}t} - e^{\mu_{b}t} \right)\qquad(6)$$
- For $t\ t_{1}$: $$b(t) = 0$$

------------------------------------------------------------------------

## Step 4: Derived Quantities

- **Clearance Time** $t_{1}$:

  $$t_{1} = \frac{1}{\mu_{y} - \mu_{b}}\log\left( 1 + \frac{\left( \mu_{y} - \mu_{b} \right)b_{0}}{\gamma y_{0}} \right)\qquad(7)$$

The expression above is indirectly represented by lines 8-12 of
`model.jags`:

``` numberSource
     beta[subj, cur_antigen_iso] <- 
       log(
         y1[subj,cur_antigen_iso] / y0[subj,cur_antigen_iso]
         ) / 
       t1[subj,cur_antigen_iso]
```

- **Peak Antibody Level** $y_{1}$:

  $$y_{1} = y_{0}e^{\mu_{y}t_{1}}\qquad(8)$$

The expression above corresponds to line 59 of `model.jags`:

``` numberSource
   y1[subj,cur_antigen_iso]    <- y0[subj,cur_antigen_iso] + exp(par[subj,cur_antigen_iso,2]) # par[,,2] must be log(y1-y0)
```

**Important**: $t_{1}$ and $y_{1}$ are **derived**, not fit parameters.

------------------------------------------------------------------------

## Full Parameter Model (7 Parameters)

**Subject-level parameters** for each subject$i$ and biomarker $j$:

$$\theta_{ij} \sim \mathcal{N}\left( \mu_{j},\,\Sigma_{j} \right),\quad\theta_{ij} = \begin{bmatrix}
y_{0,ij} \\
b_{0,ij} \\
\mu_{b,ij} \\
\mu_{y,ij} \\
\gamma_{ij} \\
\alpha_{ij} \\
\rho_{ij}
\end{bmatrix}\qquad(9)$$

- These 7 parameters represent the **full biological model** (antibody +
  pathogen dynamics)

------------------------------------------------------------------------

## From Full 7 Parameters to 5 Latent Parameters

- Although the model estimates 7 parameters, for modeling antibody
  kinetics $y(t)$, we focus on **5-parameter subset**:

$$y_{0},\ \ t_{1}\left( \text{derived} \right),\ \ y_{1}\left( \text{derived} \right),\ \ \alpha,\ \ \rho$$

- These 5 parameters are **log-transformed** into the latent parameters
  $\theta\_{ij}$ used for modeling.

------------------------------------------------------------------------

## Core Parameters Used for Curve Drawing

Although the full model estimates **7 parameters**, only **5 key
parameters** required to draw antibody curves:

- $y_{0}$: initial antibody level
- $t_{1}$: time of peak antibody response (derived)
- $y_{1}$: peak antibody level (derived)
- $\alpha$: decay rate
- $\rho$: shape of decay

Note: $t_{1}$ and $y_{1}$ are **derived from the full model** - These 5
are sufficient for prediction and plotting

------------------------------------------------------------------------

## Step 5: Subject-Level Parameters (Latent Version)

Each subject $i$ and biomarker $j$ has latent parameters:

$$\theta_{ij} = \begin{bmatrix}
{\log\left( y_{0,ij} \right)} \\
{\log\left( y_{1,ij} - y_{0,ij} \right)} \\
{\log\left( t_{1,ij} \right)} \\
{\log\left( \alpha_{ij} \right)} \\
{\log\left( \rho_{ij} - 1 \right)}
\end{bmatrix}\qquad(10)$$

Distribution:

$$\theta_{ij} \sim \mathcal{N}\left( \mu_{j},\Sigma_{j} \right)$$

The expression above reflects the prior distribution specified on line
66 of `model.jags`:

``` numberSource
   par[subj, cur_antigen_iso, 1:n_params] ~ dmnorm(mu.par[cur_antigen_iso,], prec.par[cur_antigen_iso,,])
```

------------------------------------------------------------------------

## Step 6: Parameter Transformations (log scale priors)

JAGS implements latent parameters (par) as:

| Model Parameter | Transformation in JAGS                      |
|:----------------|:--------------------------------------------|
| $y_{0}$         | $\exp\left( \text{par}_{1} \right)$         |
| $y_{1}$         | $y_{0} + \exp\left( \text{par}_{2} \right)$ |
| $t_{1}$         | $\exp\left( \text{par}_{3} \right)$         |
| $\alpha$        | $\exp\left( \text{par}_{4} \right)$         |
| $\rho$          | $\exp\left( \text{par}_{5} \right) + 1$     |

Table 2: Log-Scale Transformations of Antibody Model Parameters in JAGS.

The table above corresponds to lines 58-62 of `model.jags`:

``` numberSource
   y0[subj,cur_antigen_iso]    <- exp(par[subj,cur_antigen_iso,1])
   y1[subj,cur_antigen_iso]    <- y0[subj,cur_antigen_iso] + exp(par[subj,cur_antigen_iso,2]) # par[,,2] must be log(y1-y0)
   t1[subj,cur_antigen_iso]    <- exp(par[subj,cur_antigen_iso,3])
   alpha[subj,cur_antigen_iso] <- exp(par[subj,cur_antigen_iso,4]) # `nu` in the paper
   shape[subj,cur_antigen_iso] <- exp(par[subj,cur_antigen_iso,5]) + 1 # `r` in the paper
```

All priors are thus applied on **log scale** (or log-minus-one for
$\rho$).

------------------------------------------------------------------------

## Step 7: Population-Level Parameters (Priors)

The biomarker-specific mean vector $\mu_{j}$ has a **hyperprior** :

$$\mu_{j} \sim \mathcal{N}\left( \mu_{\text{hyp},j},\Omega_{\text{hyp},j} \right)\qquad(11)$$

Where:

- $\mu_{\text{hyp},j}$ : **prior mean** for the population-level
  parameters  
- $\Omega_{\text{hyp},j}$ : **prior covariance** encoding uncertainty
  about $\mu_{j}$ (e.g., $100 \cdot I_{7}$ for weakly informative prior)

The expression above corresponds to line 73 of `model.jags`:

``` numberSource
  mu.par[cur_antigen_iso, 1:n_params] ~ dmnorm(mu.hyp[cur_antigen_iso,], prec.hyp[cur_antigen_iso,,])
```

**Clarification:**

- $\mu_{\text{hyp},j}$ defines the **center of a distribution, not** a
  single point guess.

- In Bayesian modeling, **priors and hyperpriors are distributions**
  over unknown quantities, capturing full uncertainty.

------------------------------------------------------------------------

## Step 8: Prior on Covariance Matrices

We also don’t know how much individual parameters vary. So we assign a
**Wishart prior** to the **inverse** covariance matrix:

$$\Sigma_{j}^{-1} \sim \mathcal{W}\left( \Omega_{j},\nu_{j} \right)\qquad(12)$$

- $\Omega_{j}$ : prior scale matrix (small variance across parameters,
  often $0.1 \cdot I_{7}$)
- $\nu_{j}$ : degrees of freedom

The expression above corresponds to line 74 of `model.jags`:

``` numberSource
  prec.par[cur_antigen_iso, 1:n_params, 1:n_params] ~ dwish(omega[cur_antigen_iso,,], wishdf[cur_antigen_iso])
```

Higher $\nu_{j}$$\rightarrow$ more informative prior (stronger prior).

Lower $\nu_{j}$$\rightarrow$ more weakly informative (broader prior or
weaker prior).

This tells the model how much we expect individuals to vary from the
average for biomarker $j$.

------------------------------------------------------------------------

## Putting It All Together

The model is built hierarchically across five conceptual levels:

1.  **Observed data:** noisy log antibody concentrations from serum
    samples
2.  **Latent individual parameters:** hidden antibody dynamics
    $\theta_{ij}$ for each subject-biomarker pair
3.  **Population-level means:** average antibody parameters for each
    biomarker
4.  **Hyperpriors on means:** our belief about the likely range of
    biomarker-specific population means
5.  **Priors on variability:** our belief about how much individual
    parameters vary around the population mean

This structure allows us to account for uncertainty at every level,
while borrowing strength across subjects and biomarkers.

------------------------------------------------------------------------

## Summary of the Hierarchy

1.  **Top Level**:

    - For each biomarker $j$, the true mean antibody trajectory
      parameters $\mu_{j}$ come from a prior:
      - $\mu_{j} \sim \mathcal{N}\left( \mu_{\text{hyp},j},\Omega_{\text{hyp},j} \right)$

2.  **Middle Level**:

    - For each person $i$, their parameters:
      - $\theta_{ij} \sim \mathcal{N}\left( \mu_{j},\Sigma_{j} \right)$

3.  **Bottom Level**:

    - Their actual observed antibody levels are noisy measurements of
      predictions from $\theta_{ij}$:
      - $\log\left( y_{\text{obs},ij} \right) \sim \mathcal{N}\left( \mu_{\log y,ij},\tau_{j}^{-1} \right)$

Where:

- $\mu_{\log y,ij}$ is the **expected log antibody level**, computed
  from the two-phase model using subject-level parameters $\theta_{ij}$.
- Predictions use $\theta_{ij}$ to compute $\mu_{\log y,ij}$, which is
  then compared to the observed log antibody data.

------------------------------------------------------------------------

## Clarification: How Bottom Level Depends on Middle Level

We know the following facts:

1.  $\theta_{ij}$ are the **subject-level latent parameters** (like
    $y_{0},b_{0},\mu\_ b,\mu\_ y,\gamma,\alpha,\rho$).
2.  From $\theta_{ij}$, we calculate the expected **log antibody level**
    $\mu_{\log y,ij}$ using the ODE-based two-phase model.
3.  The **observed log-antibody** $\log\left( y_{\text{obs},ij} \right)$
    is modeled as a **noisy version** of $\mu_{\log y,ij}$.
4.  $\tau_{j}$ is the precision (measurement noise precision for
    biomarker $j$).

Thus, at the **Bottom Level**, we model:

$$\log\left( y_{\text{obs},ij} \right) \sim \mathcal{N}\left( \mu_{\log y,ij},\tau_{j}^{-1} \right)$$

Here:

- The **mean** is $\mu_{\log y,ij}$ — derived from the **ODE solution**
  using $\theta_{ij}$.
- The **variance** is $\tau_{j}^{-1}$ — shared across individuals for a
  given biomarker.

Summary:

- Observations depend indirectly on latent parameters $\theta_{ij}$ via
  the predicted log antibody levels $\mu_{\log y,ij}$.

------------------------------------------------------------------------

## Summary Mapping of Notation

| Symbol                              | Meaning                                                             | JAGS Variable                              |
|-------------------------------------|---------------------------------------------------------------------|--------------------------------------------|
| $i$                                 | Subject index                                                       | `subj`                                     |
| $j$                                 | Antigen-isotype (biomarker) index                                   | `cur_antigen_iso`                          |
| $y_{\text{obs},ij}$                 | Observed antibody concentration at a timepoint                      | `logy[subj, obs, cur_antigen_iso]`         |
| $\mu_{\log y,ij}$                   | Expected log antibody level based on ODE model using $\theta_{ij}$  | `mu.logy[subj, obs, cur_antigen_iso]`      |
| $\theta_{ij}$                       | Subject-level latent parameters for modeling $y(t)$                 | `par[subj, cur_antigen_iso, 1:n_params]`   |
| $\mu_{j}$                           | Mean vector of latent parameters across subjects for biomarker $j$  | `mu.par[cur_antigen_iso, ]`                |
| $\Sigma_{j}$                        | Covariance matrix of latent parameters for biomarker $j$            | `inverse of prec.par[cur_antigen_iso, , ]` |
| $\tau_{j}$                          | Precision (inverse variance) of measurement error for biomarker $j$ | `prec.logy[cur_antigen_iso]`               |
| $\left( a_{j},b_{j} \right)$        | Gamma prior hyperparameters for $\tau_{j}$                          | `prec.logy.hyp[cur_antigen_iso, 1/2]`      |
| $\mu_{\text{hyp},j}$                | Prior mean for $\mu_{j}$                                            | `mu.hyp[cur_antigen_iso, ]`                |
| $\Omega_{\text{hyp},j}$             | Prior precision for $\mu_{j}$                                       | `prec.hyp[cur_antigen_iso, , ]`            |
| $\left( \Omega_{j},\nu_{j} \right)$ | Wishart scale and degrees of freedom for $\Sigma_{j}^{-1}$          | `omega[cur_antigen_iso, , ], wishdf[...]`  |

------------------------------------------------------------------------

## Model Comparison ([Teunis and Eijkeren 2016](#ref-teunis2016)) vs. Our Presentation

| Component           | ([Teunis and Eijkeren 2016](#ref-teunis2016)) | This Presentation           |
|:--------------------|:----------------------------------------------|:----------------------------|
| Pathogen ODE        | $\mu_{0}b(t) - cy(t)$                         | $\mu_{b}b(t) - \gamma y(t)$ |
| Antibody growth ODE | $\mu y(t)$                                    | $\mu_{y}y(t)$               |
| Antibody decay ODE  | $-\alpha y(t)^{r}$                            | $-\alpha y(t)^{\rho}$       |
| Growth mechanism    | Pathogen-driven                               | Self-driven                 |

Table 3: Comparison of Teunis (2016) model and this presentation’s model
assumptions.

Teunis, Peter F. M., and J. C. H. van Eijkeren. 2016. “Linking the
Seroresponse to Infection to Within-Host Heterogeneity in Antibody
Production.” *Epidemics* 16: 33–39.
<https://doi.org/10.1016/j.epidem.2016.04.001>.
