# Stochastic Model for Differential Power Analysis: Implementation Guide
A step-by-step explanation of the stochastic model for Differential Power Analysis (DPA) as described in the research paper "A Stochastic Model for Differential Side Channel Cryptanalysis" by Werner Schindler, Kerstin Lemke, and Christof Paar. The explanation focuses on:
- Forming the basis functions for the vector subspace approximation.
- How these basis functions are used in the profiling phase.
- How the overall attack works.

## Overview of the Stochastic Model (From the Paper)
- **Leakage Model**: At time \( t \), the trace sample is \( I_t(x, k) = h_t(x, k) + R_t \), where \( h_t \) is deterministic data-dependent leakage, and \( R_t \) is noise (Eq. 1).
- **Subspace Approximation**: Approximate \( h_t \) in a low-dimensional vector subspace \( \mathcal{F}_{u;t} \) spanned by basis functions \( g_{j,t} \) (Eq. 4), using coefficients \( \beta \): \( \tilde{h}_t^*(x, k) = \sum \beta_j g_{j,t}(x, k) \) (Eq. 9).
- **EIS Property**: Basis depends on \( \phi = x \oplus k \) (Definition 2, Lemma 1), allowing profiling with one key.
- **Bit-Wise Model**: Basis = constant + bits of S-Box[\( \phi \)] (Section 3.1, F5 for 4-bit analog to F9).

The attack has two phases: profiling (estimate \( \beta \)) and extraction (guess key using minimum or ML principle).

## Step 1: Forming the Basis Functions
The basis functions quantify expected leakage from intermediates (e.g., bits of S-Box output). Precompute a matrix G (16x5 for 4-bit) for all \( \phi \) (0-15).

### Steps to Form Basis Functions
1. **Define S-Box**: Use the paper's bit-wise model (Section 3.1: selection function S(\( \phi \)), where \( \phi = x \oplus k \)).

2. **Precompute G Matrix**:
   - For each \( \phi = 0 \) to 15:
     - Compute S-Box[\( \phi \)] (integer).
     - Convert to 4-bit binary (MSB to LSB as floats 0.0/1.0).
     - G[\( \phi \)] = [1.0 (constant)] + [bit0, bit1, bit2, bit3].
   - This exploits EIS (Lemma 1: leakage same for equivalent \( \phi \)).

3. **Output**: G (16x5 matrix), rows for \( \phi \), columns for basis.

### Code Implementation
```python
class BasisFunctions:
    def __init__(self, sbox):
        self.sbox = sbox
        self.num_basis = 5  # u=5: constant + 4 bits
        self.G = self._build_basis_matrix()

     def _build_basis_matrix(self):
        G = np.zeros((16, self.num_basis), dtype=float)
        for phi in range(16):
            sbox_output = self.sbox[phi]
            if(self.basis_type == 'bits'):
                G[phi] = [1.0]+[float(i) for i in format(sbox_output, '04b')]
            elif(self.basis_type == 'hw_bits'):
                G[phi] = [1.0] + [float(i) for i in format(bin(sbox_output).count('1'),'04b')]
        return G
```

- **Example G for Custom S-Box**: For \( \phi = 7 \), S-Box[7]=10 (0xA, binary '1010') → G[7] = [1.0, 1.0, 0.0, 1.0, 0.0].

## Step 2: Using Basis Functions in Profiling
Profiling estimates \( \beta \) per time t (Theorem 3: least-squares minimization, Eq. 11-13) using known key k_b and traces.

### Steps in Profiling
1. **Compute Intermediates**: phi_prof = x_prof XOR k_b (N1 x 1).

2. **Form Design Matrix**: G_prof = G[phi_prof] (N1 x 5, A in Eq. 11).

3. **Fit Betas per Time t**:
   - For each t in segment:
     - i_t = traces_prof[:, t] (N1 x 1).
     - beta_t = lstsq(G_prof, i_t) (solves (G_prof^T G_prof) beta = G_prof^T i_t, Eq. 12).
   - betas: segment_length x 5 matrix.

4. **Select Time Points**: Compute norm_b = norm(betas[:,1:]) per t (exclude constant). Use modes S1-S6 (Section 3.3, threshold τ).

5. **(Optional) Covariance**: For ML, residuals = traces_noise[:, ts] - predicted h (Eq. 14).

### Code Implementation
```python
class Profiling:
    def __init__(self, basis_functions):
        self.basis_functions = basis_functions
        self.betas = None
        self.ts = None
        self.cov = None

    def estimate_betas(self, traces_prof, x_prof, k_b, start_time, end_time):
        N1 = len(x_prof)
        phi_prof = np.bitwise_xor(x_prof, k_b) & 0x0F
        G_prof = self.basis_functions.G[phi_prof]
        segment_length = end_time - start_time
        self.betas = np.zeros((segment_length, 5), dtype=float)
        self.start_time = start_time
        for t_rel, t_abs in enumerate(range(start_time, end_time)):
            i_t = traces_prof[:, t_abs]
            beta_t, _, _, _ = lstsq(G_prof, i_t, lapack_driver='gelsy')
            self.betas[t_rel] = beta_t

    # select_time_points and estimate_covariance as in code...
```

- **Alignment with Paper**: Fits h^* (Theorem 2), separate per t (Theorem 1(ii)).

## Step 3: How the Attack Works
The attack has profiling (known key) and extraction (guess key) phases.

### Steps in the Attack
1. **Profiling Phase** (Section 2.2):
   - Form basis G (as above).
   - Estimate betas (as above).
   - Select ts where norm_b high (Section 3.3).
   - (For ML) Estimate cov from residuals.

2. **Key Extraction Phase** (Section 2.3):
   - For each hypothesis k' (0-15):
     - Compute phi_j = x_attack[j] XOR k' for each attack trace j.
     - Predict h_j = G[phi_j] @ betas[ts] (m x 1 per trace).
     - Observe i_j = traces_attack[j, ts] (m x 1).
     - Minimum: Sum/avg (i_j - h_j)^2 over j and m (Eq. 19).
     - ML: Sum delta^T cov_inv delta (Eq. 16).
   - Pick k' with min value (correct minimizes expected error, Eq. 18).

3. **Success Rate Evaluation**: Repeat with subsets, compute % correct guesses (paper Table 1).

### Code Implementation (Extraction)
```python
class KeyExtraction:
    def __init__(self, profiling):
        self.profiling = profiling
        # ... (as in code)

    def extract_key(self, traces_attack, x_attack, N3, method='minimum'):
        m = len(self.ts)
        G = self.basis_functions.G
        min_diff = float('inf')
        best_k = None
        for k_prime in range(16):
            diff = 0.0
            for j in range(N3):
                phi_j = np.bitwise_xor(x_attack[j], k_prime) & 0x0F
                h_j = np.array([G[phi_j] @ self.betas[t] for t in self.ts])
                i_j = traces_attack[j, self.ts]
                diff += np.sum((i_j - h_j) ** 2)
            avg_diff = diff / N3
            if avg_diff < min_diff:
                min_diff = avg_diff
                best_k = k_prime
        return best_k
```

- **Alignment with Paper**: Minimum principle (Eq. 19), uses betas from profiling.

For full attack, run `run_stochastic_dpa` (as in code). Test with known key traces to validate.
