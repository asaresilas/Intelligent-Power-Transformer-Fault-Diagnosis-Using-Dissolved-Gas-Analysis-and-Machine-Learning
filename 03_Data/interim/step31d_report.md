# Step 31D report - Study 2 measures (EXPLORATORY)

## Table 4.12 (primary variant)

| held_out | model | n | macro_f1 | macro_f1_lo | macro_f1_hi | strict_accuracy | coverage |
|---|---|---|---|---|---|---|---|
| DISTRAIN | B | 439 | 0.679 | 0.635 | 0.722 | 0.699 | 1.0 |
| DISTRAIN | C | 439 | 0.63 | 0.583 | 0.673 | 0.656 | 1.0 |
| DISTRAIN | IEC60599 | 439 | 0.483 | 0.433 | 0.53 | 0.469 | 0.738 |
| DISTRAIN | Rogers | 439 | 0.383 | 0.336 | 0.425 | 0.369 | 0.642 |
| DISTRAIN | Duval | 439 | 0.541 | 0.493 | 0.586 | 0.56 | 0.998 |
| DISTEST | A | 61 | 0.793 | 0.682 | 0.895 | 0.82 | 1.0 |
| DISTEST | B | 61 | 0.851 | 0.753 | 0.936 | 0.869 | 1.0 |
| DISTEST | C | 61 | 0.873 | 0.777 | 0.948 | 0.885 | 1.0 |
| DISTEST | IEC60599 | 61 | 0.473 | 0.333 | 0.589 | 0.475 | 0.721 |
| DISTEST | Rogers | 61 | 0.289 | 0.196 | 0.371 | 0.328 | 0.623 |
| DISTEST | Duval | 61 | 0.543 | 0.43 | 0.639 | 0.59 | 1.0 |
| IECTC10 | A | 58 | 0.731 | 0.622 | 0.831 | 0.724 | 1.0 |
| IECTC10 | B | 58 | 0.782 | 0.678 | 0.872 | 0.776 | 1.0 |
| IECTC10 | C | 58 | 0.821 | 0.721 | 0.905 | 0.81 | 1.0 |
| IECTC10 | IEC60599 | 58 | 0.731 | 0.623 | 0.828 | 0.638 | 0.879 |
| IECTC10 | Rogers | 58 | 0.33 | 0.246 | 0.412 | 0.483 | 0.724 |
| IECTC10 | Duval | 58 | 0.752 | 0.627 | 0.882 | 0.776 | 1.0 |
| LI2019 | A | 85 | 0.628 | 0.519 | 0.733 | 0.647 | 1.0 |
| LI2019 | B | 85 | 0.651 | 0.546 | 0.753 | 0.659 | 1.0 |
| LI2019 | C | 85 | 0.654 | 0.546 | 0.754 | 0.659 | 1.0 |
| LI2019 | IEC60599 | 85 | 0.477 | 0.35 | 0.584 | 0.306 | 0.788 |
| LI2019 | Rogers | 85 | 0.269 | 0.176 | 0.354 | 0.188 | 0.682 |
| LI2019 | Duval | 85 | 0.626 | 0.508 | 0.727 | 0.471 | 1.0 |

## Contrasts (all variants)

| variant | held_out | contrast | macro_f1_diff | diff_lo | diff_hi | b | c | p | p_holm |
|---|---|---|---|---|---|---|---|---|---|
| equal_source_weight | DISTRAIN | C - B | -0.008 | -0.025 | 0.009 | 4 | 6 | 0.754 | 0.754 |
| equal_source_weight | DISTRAIN | C - Duval | 0.101 | 0.049 | 0.153 | 103 | 56 | 0.0 | 0.001 |
| equal_source_weight | DISTEST | B - A | 0.002 | -0.113 | 0.108 | 5 | 5 | 1.0 | 1.0 |
| equal_source_weight | DISTEST | C - B | 0.056 | 0.0 | 0.129 | 3 | 0 | 0.25 | 0.5 |
| equal_source_weight | DISTEST | C - Duval | 0.308 | 0.2 | 0.422 | 20 | 3 | 0.0 | 0.001 |
| equal_source_weight | IECTC10 | B - A | 0.086 | 0.018 | 0.166 | 5 | 0 | 0.062 | 0.188 |
| equal_source_weight | IECTC10 | C - B | 0.014 | -0.045 | 0.077 | 2 | 1 | 1.0 | 1.0 |
| equal_source_weight | IECTC10 | C - Duval | 0.079 | -0.071 | 0.214 | 7 | 4 | 0.549 | 1.0 |
| equal_source_weight | LI2019 | B - A | 0.006 | -0.069 | 0.08 | 5 | 6 | 1.0 | 1.0 |
| equal_source_weight | LI2019 | C - B | 0.038 | 0.001 | 0.087 | 3 | 0 | 0.25 | 0.5 |
| equal_source_weight | LI2019 | C - Duval | 0.046 | -0.1 | 0.194 | 26 | 9 | 0.007 | 0.021 |
| iec_all | DISTRAIN | C - B | 0.032 | 0.012 | 0.055 | 12 | 2 | 0.013 | 0.013 |
| iec_all | DISTRAIN | C - Duval | 0.117 | 0.068 | 0.167 | 99 | 47 | 0.0 | 0.0 |
| iec_all | DISTEST | B - A | 0.058 | -0.03 | 0.145 | 5 | 2 | 0.453 | 0.906 |
| iec_all | DISTEST | C - B | 0.008 | -0.031 | 0.065 | 1 | 1 | 1.0 | 1.0 |
| iec_all | DISTEST | C - Duval | 0.316 | 0.182 | 0.451 | 21 | 4 | 0.001 | 0.004 |
| iec_all | IECTC10 | B - A | 0.059 | 0.015 | 0.114 | 6 | 0 | 0.031 | 0.094 |
| iec_all | IECTC10 | C - B | 0.022 | 0.0 | 0.057 | 2 | 0 | 0.5 | 1.0 |
| iec_all | IECTC10 | C - Duval | 0.027 | -0.049 | 0.112 | 13 | 9 | 0.523 | 1.0 |
| iec_all | LI2019 | B - A | 0.081 | 0.01 | 0.159 | 7 | 2 | 0.18 | 0.359 |
| iec_all | LI2019 | C - B | -0.033 | -0.1 | 0.031 | 1 | 4 | 0.375 | 0.375 |
| iec_all | LI2019 | C - Duval | 0.05 | -0.075 | 0.197 | 26 | 9 | 0.007 | 0.021 |
| primary | DISTRAIN | C - B | -0.05 | -0.076 | -0.025 | 6 | 25 | 0.001 | 0.002 |
| primary | DISTRAIN | C - Duval | 0.088 | 0.04 | 0.141 | 99 | 57 | 0.001 | 0.002 |
| primary | DISTEST | B - A | 0.058 | -0.026 | 0.149 | 5 | 2 | 0.453 | 0.906 |
| primary | DISTEST | C - B | 0.022 | 0.0 | 0.069 | 1 | 0 | 1.0 | 1.0 |
| primary | DISTEST | C - Duval | 0.33 | 0.192 | 0.469 | 22 | 4 | 0.001 | 0.003 |
| primary | IECTC10 | B - A | 0.052 | 0.0 | 0.118 | 3 | 0 | 0.25 | 0.75 |
| primary | IECTC10 | C - B | 0.038 | 0.0 | 0.097 | 2 | 0 | 0.5 | 1.0 |
| primary | IECTC10 | C - Duval | 0.069 | -0.084 | 0.203 | 7 | 5 | 0.774 | 1.0 |
| primary | LI2019 | B - A | 0.023 | -0.036 | 0.09 | 4 | 3 | 1.0 | 1.0 |
| primary | LI2019 | C - B | 0.003 | -0.024 | 0.028 | 1 | 1 | 1.0 | 1.0 |
| primary | LI2019 | C - Duval | 0.028 | -0.131 | 0.186 | 27 | 11 | 0.015 | 0.045 |

## Reject option (model C, primary)

| held_out | method | method_coverage | selective_accuracy | method_conditional_accuracy | diff | diff_lo | diff_hi |
|---|---|---|---|---|---|---|---|
| DISTRAIN | IEC60599 | 0.738 | 0.725 | 0.636 | 0.09 | 0.029 | 0.148 |
| DISTRAIN | Rogers | 0.642 | 0.777 | 0.574 | 0.202 | 0.139 | 0.261 |
| DISTEST | IEC60599 | 0.721 | 0.955 | 0.659 | 0.295 | 0.161 | 0.427 |
| DISTEST | Rogers | 0.623 | 0.947 | 0.526 | 0.421 | 0.282 | 0.55 |
| IECTC10 | IEC60599 | 0.879 | 0.824 | 0.725 | 0.098 | -0.008 | 0.212 |
| IECTC10 | Rogers | 0.724 | 0.881 | 0.667 | 0.214 | 0.064 | 0.357 |
| LI2019 | IEC60599 | 0.788 | 0.731 | 0.388 | 0.343 | 0.213 | 0.465 |
| LI2019 | Rogers | 0.682 | 0.776 | 0.276 | 0.5 | 0.36 | 0.632 |
