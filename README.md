# Stochastic Differential Side-Channel Analysis (DSCA)

This repository provides an implementation of the **Stochastic Model for Differential Side-Channel Cryptanalysis (DSCA)**, based on the work of *Schindler, Lemke, and Paar*.
The stochastic model combines statistical regression and side-channel analysis to efficiently approximate leakage behavior and recover secret keys with fewer traces than traditional template attacks.

---

## Overview

The stochastic DSCA method models the side-channel leakage as a linear combination of predefined **basis functions**, enabling efficient profiling and key extraction.
It consists of three major stages:

1. **Basis Function Selection**
2. **Profiling Phase**
3. **Key Extraction Phase**

---

## 1. Basis Function Selection

The leakage model assumes that the observed signal ( I_t(x,k) ) can be decomposed as:

$I_t(x,k) = h_t(x,k) + R_t$

where ($h_t(x,k)$) is the deterministic (data-dependent) component and ($R_t$) represents noise.

To approximate ($h_t(x,k)$), a set of **basis functions** (${ g_{0,t}, g_{1,t}, \dots, g_{u-1,t}}$ ) is defined.
Typical choices include:

* `hw`: Hamming Weight
* `hw_bits`: Bit-wise decomposition of the Hamming weight
* `bits`: Individual bits of S-box output
* `lsb`: Least Significant Bit

The leakage function is modeled as:

$h_t^*(x,k) = \sum_{j=0}^{u-1} \beta_{j,t}, g_{j,t}(x,k)$  
where ($\beta_{j,t}$) are coefficients estimated during profiling.

---

## Profiling Phase

The **profiling phase** builds the regression model that estimates the deterministic part of the leakage.

1. **Data Collection:**

   * Collect ($N_1$) profiling traces under a known key ($k_b$).
   * Each trace corresponds to known plaintexts ($x_i$).

2. **Coefficient Estimation:**
   Using least-squares regression:
   
   $\beta_t = (G^\top G)^{-1} G^\top I_t$,
   
   where:

   * ($I_t$) is the measured leakage vector at time ($t$).
   * ($G$) is the basis matrix constructed from the selected basis functions.

3. **Deterministic Leakage Estimation:**
   The approximated leakage is then:
   
   $\hat{h}_t(x,k_b) = G(\phi(x,k_b)) , \beta_t$.
   

4. **Time Point Selection:**
   Compute the coefficient norm ( $| \beta_t |$ ) across all time instants and select points with the strongest data dependence for key extraction.

5. **Noise Covariance Estimation (Optional):**
   For the maximum-likelihood approach, compute the covariance matrix ( C ) from the residuals:
   
   $r_{i,t} = I_t(x_i,k_b) - \hat{h}_t(x_i,k_b)$.


---

## Key Extraction Phase

In this phase, ($N_3$) traces are collected from the **target device** under an **unknown key** ($k^\circ$).

For each candidate key ( k' ):

$\hat{I}_t(x,k') = G(\phi(x,k')) , \beta_t$.


### Minimum Principle

The correct key minimizes the mean squared error:

$k^* = \arg\min_{k'} \frac{1}{N_3} \sum_{j=1}^{N_3}
| I_t(x_j,k^\circ) - \hat{I}_t(x_j,k') |^2$.


### Maximum Likelihood Principle

If the noise is Gaussian with covariance matrix ( C ):

$k^* = \arg\min_{k'} 
\sum_{j=1}^{N_3}
\left( 
\big(i^{(j)} - \tilde{h}_t(x_j, k')\big)^\top 
C^{-1} 
\big(i^{(j)} - \tilde{h}_t(x_j, k')\big)
\right)$

The **maximum likelihood principle** provides better robustness in noisy environments, while the **minimum principle** offers faster computation.

---
