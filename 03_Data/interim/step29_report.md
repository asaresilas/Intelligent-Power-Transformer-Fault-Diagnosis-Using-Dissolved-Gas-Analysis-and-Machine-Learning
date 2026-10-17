# Step 29 report - performance measures

B = 2000, seed 20261010; Wilson for proportions; merged file verified.

## Table 4.5 - main comparison (primary sets, primary scoring)

| evaluation_set | method_label | n | strict_accuracy | conditional_accuracy | coverage | macro_f1 |
|---|---|---|---|---|---|---|
| Internal test | ML (selected model) | 61 | 0.820 [0.705, 0.896] | 0.820 [0.705, 0.896] | 1.000 [0.941, 1.000] | 0.812 [0.711, 0.900] |
| Internal test | Rogers Ratio | 61 | 0.328 [0.223, 0.453] | 0.526 [0.373, 0.675] | 0.623 [0.497, 0.734] | 0.282 [0.190, 0.362] |
| Internal test | IEC 60599 ratio | 61 | 0.475 [0.355, 0.598] | 0.659 [0.511, 0.781] | 0.721 [0.598, 0.818] | 0.501 [0.359, 0.606] |
| Internal test | Duval Triangle 1 | 61 | 0.557 [0.433, 0.675] | 0.557 [0.433, 0.675] | 1.000 [0.941, 1.000] | 0.528 [0.414, 0.621] |
| IEC TC 10 (power transformers) | ML (selected model) | 58 | 0.724 [0.598, 0.822] | 0.724 [0.598, 0.822] | 1.000 [0.938, 1.000] | 0.731 [0.611, 0.827] |
| IEC TC 10 (power transformers) | Rogers Ratio | 58 | 0.483 [0.359, 0.608] | 0.667 [0.516, 0.790] | 0.724 [0.598, 0.822] | 0.330 [0.248, 0.411] |
| IEC TC 10 (power transformers) | IEC 60599 ratio | 58 | 0.638 [0.509, 0.749] | 0.725 [0.591, 0.829] | 0.879 [0.771, 0.940] | 0.731 [0.616, 0.820] |
| IEC TC 10 (power transformers) | Duval Triangle 1 | 58 | 0.776 [0.653, 0.864] | 0.776 [0.653, 0.864] | 1.000 [0.938, 1.000] | 0.752 [0.626, 0.891] |
| Li 2019 | ML (selected model) | 86 | 0.628 [0.522, 0.723] | 0.628 [0.522, 0.723] | 1.000 [0.957, 1.000] | 0.595 [0.480, 0.700] |
| Li 2019 | Rogers Ratio | 86 | 0.174 [0.109, 0.268] | 0.254 [0.161, 0.378] | 0.686 [0.582, 0.774] | 0.256 [0.160, 0.341] |
| Li 2019 | IEC 60599 ratio | 86 | 0.302 [0.215, 0.406] | 0.382 [0.276, 0.501] | 0.791 [0.693, 0.863] | 0.436 [0.307, 0.539] |
| Li 2019 | Duval Triangle 1 | 86 | 0.453 [0.353, 0.558] | 0.453 [0.353, 0.558] | 1.000 [0.957, 1.000] | 0.564 [0.447, 0.659] |

## Differences ML minus each method (primary scoring)

| evaluation_set | primary_set | variant | method | strict_gap | strict_gap_lo | strict_gap_hi | conditional_gap | macro_f1_gap | macro_f1_gap_lo | macro_f1_gap_hi | criterion2_conditional_gap_smaller |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Internal test | True | primary | Rogers | 0.4918 | 0.377 | 0.6066 | 0.2934 | 0.5299 | 0.4191 | 0.6537 | True |
| Internal test | True | primary | IEC60599 | 0.3443 | 0.2295 | 0.4754 | 0.1606 | 0.3112 | 0.1915 | 0.4674 | True |
| Internal test | True | primary | Duval | 0.2623 | 0.1311 | 0.3934 | 0.2623 | 0.2834 | 0.145 | 0.4295 | False |
| IEC TC 10 (power transformers) | True | primary | Rogers | 0.2414 | 0.1207 | 0.3448 | 0.0575 | 0.4009 | 0.2921 | 0.5024 | True |
| IEC TC 10 (power transformers) | True | primary | IEC60599 | 0.0862 | -0.0172 | 0.1897 | -0.0014 | -0.0004 | -0.075 | 0.0805 | True |
| IEC TC 10 (power transformers) | True | primary | Duval | -0.0517 | -0.1724 | 0.069 | -0.0517 | -0.021 | -0.2004 | 0.132 | False |
| Li 2019 | True | primary | Rogers | 0.4535 | 0.3488 | 0.5581 | 0.3737 | 0.3398 | 0.2236 | 0.4607 | True |
| Li 2019 | True | primary | IEC60599 | 0.3256 | 0.2209 | 0.4302 | 0.2456 | 0.1595 | 0.0542 | 0.2929 | True |
| Li 2019 | True | primary | Duval | 0.1744 | 0.0349 | 0.314 | 0.1744 | 0.031 | -0.1219 | 0.1918 | False |

## Sensitivity (strict accuracy / macro-F1 by variant, primary sets)

| evaluation_set | method | dual_wrong | lower_gate | no_gate | primary |
|---|---|---|---|---|---|
| IEC TC 10 (power transformers) | Duval | 0.776 | 0.828 | 0.897 | 0.776 |
| IEC TC 10 (power transformers) | IEC60599 | 0.448 | 0.655 | 0.724 | 0.638 |
| IEC TC 10 (power transformers) | ML | nan | nan | nan | 0.724 |
| IEC TC 10 (power transformers) | Rogers | 0.483 | 0.5 | 0.534 | 0.483 |
| Internal test | Duval | 0.557 | 0.623 | 0.525 | 0.557 |
| Internal test | IEC60599 | 0.459 | 0.541 | 0.426 | 0.475 |
| Internal test | ML | nan | nan | nan | 0.82 |
| Internal test | Rogers | 0.328 | 0.41 | 0.361 | 0.328 |
| Li 2019 | Duval | 0.453 | 0.709 | 0.744 | 0.453 |
| Li 2019 | IEC60599 | 0.256 | 0.442 | 0.442 | 0.302 |
| Li 2019 | ML | nan | nan | nan | 0.628 |
| Li 2019 | Rogers | 0.174 | 0.256 | 0.256 | 0.174 |
