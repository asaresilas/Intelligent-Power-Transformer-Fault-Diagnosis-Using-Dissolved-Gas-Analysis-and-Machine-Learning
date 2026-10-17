# Step 23 report - explaining the fitted model

Fitted pipeline verified (SHA-256 1C46D10391429385...). R = 30 shuffles, seed 20261010.

## Permutation importance - gas level (mean drop in macro-F1)

| feature | IEC TC 10 (power transformers) | Internal test | Li 2019 |
|---|---|---|---|
| C2H2 | 0.3708 | 0.2567 | 0.277 |
| C2H4 | 0.2236 | 0.3602 | 0.2852 |
| C2H6 | -0.0328 | 0.2413 | 0.0971 |
| CH4 | 0.1274 | 0.0911 | 0.0315 |
| H2 | 0.2876 | 0.2414 | 0.1115 |

## SHAP - mean absolute value summed over classes

| feature | development | test |
|---|---|---|
| duval_pct_C2H2 | 0.2372 | 0.2716 |
| log_R1 | 0.2117 | 0.2065 |
| log_R5 | 0.199 | 0.1979 |
| pct_C2H2 | 0.1956 | 0.2315 |
| pct_C2H4 | 0.1943 | 0.194 |
| log_R2 | 0.162 | 0.1569 |
| log_C2H4 | 0.1298 | 0.1188 |
| pct_H2 | 0.1244 | 0.127 |
| log_R4 | 0.1115 | 0.1041 |
| log_H2 | 0.1055 | 0.0827 |
| log_C2H2 | 0.1049 | 0.1209 |
| log_R3 | 0.1001 | 0.1134 |
| log_C2H6 | 0.0964 | 0.067 |
| pct_C2H6 | 0.0787 | 0.0661 |
| duval_pct_C2H4 | 0.0707 | 0.0743 |
| pct_CH4 | 0.0661 | 0.0627 |
| duval_pct_CH4 | 0.0595 | 0.0553 |
| log_CH4 | 0.0516 | 0.0512 |

Rank agreement development vs test (Spearman): 0.961. Additivity error (max |base + sum SHAP - probability|): development 9.99e-16, test 8.88e-16.

## Engineering expectation (D20), reported as found

| class | expected_gases | top3_features | matching_features | consistent |
|---|---|---|---|---|
| PD | H2 | log_R1; log_H2; pct_H2 | log_R1; log_H2; pct_H2 | True |
| D1 | C2H2 | duval_pct_C2H2; pct_C2H2; log_R1 | duval_pct_C2H2; pct_C2H2 | True |
| D2 | C2H2 | duval_pct_C2H2; pct_C2H2; log_C2H2 | duval_pct_C2H2; pct_C2H2; log_C2H2 | True |
| T1 | C2H6/CH4 | log_R1; log_R5; log_R4 | log_R1; log_R5; log_R4 | True |
| T2 | C2H4/CH4 | log_R5; pct_C2H4; log_C2H4 | log_R5; pct_C2H4; log_C2H4 | True |
| T3 | C2H4 | log_R5; pct_C2H4; log_R2 | log_R5; pct_C2H4; log_R2 | True |
