# Methods to identify the leakage points 

## Test vector Leakage Assesment (TVLA)  
TVLA is a statistical method used in Differential Power Analysis (DPA) to detect side-channel leakage in cryptographic devices. By comparing power traces from fixed (e.g., all-zero) and random plaintext inputs using Welch’s t-test, TVLA identifies significant differences in power consumption that may indicate vulnerabilities to side-channel attacks. This implementation processes 10,000 traces per group, computing t-statistics to highlight leakage points where |t| > 4.5, with visualization via Matplotlib.  
<img width="1189" height="790" alt="image" src="https://github.com/user-attachments/assets/109d313b-9105-4dbc-94df-4374baa324ea" />

## Mutual Information Analysis

Mutual Information (MI) Analysis is a statistical method to detect side-channel leakage in cryptographic devices by measuring the dependency between power traces and a leakage model (e.g., Hamming weight of plaintext bytes). This implementation computes MI for each time point across 16 bytes of AES-128 plaintexts, identifying high-MI points as potential leakage sites.

## Correlation Power Analysis

Correlation Power Analysis(CPA) uses an intermediate value(Output of the 1st SBOX operation) that is a function of part of the key and known data. The power consumption of the devices when the intermediate value is processed is estimated for each key guess. Correlation is then used to find out which key was most likely used by correlating the hypothetical power and the real power consumption. Below image shows that correlation of Hamming weight of the 1st SBOX operation and power consumption during that interval is positive and able to extract the correct key. 

![cpa](https://github.com/user-attachments/assets/358df3a0-ef30-437b-8ef2-0012eb91928e)
