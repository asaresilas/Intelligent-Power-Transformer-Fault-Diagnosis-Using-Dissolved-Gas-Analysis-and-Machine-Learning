# Step 11 report - describe the data

Run date: 2026-10-13. Script: `06_Python_ML/src/analysis/step11_describe.py`. Values: dga_master.csv with decision D8 (not detected = 0 ppm).

## Table 4.1 - records by data role and class

| Set | Normal | PD | D1 | D2 | T1 | T2 | T12 | T3 | Total |
|---|---|---|---|---|---|---|---|---|---|
| Development | 75 | 37 | 53 | 85 | 80 | 39 | 0 | 70 | 439 |
| Internal test (all) | 10 | 10 | 10 | 10 | 10 | 10 | 0 | 10 | 70 |
|   of which independent of benchmark | 10 | 7 | 7 | 8 | 10 | 10 | 0 | 9 | 61 |
| Benchmark IEC TC 10, all equipment | 0 | 9 | 26 | 48 | 0 | 0 | 16 | 18 | 117 |
|   of which power transformers (primary) | 0 | 1 | 10 | 27 | 0 | 0 | 8 | 12 | 58 |
| External test Li 2019 (all) | 0 | 16 | 49 | 54 | 19 | 9 | 16 | 38 | 201 |
|   of which independent of benchmark | 0 | 8 | 23 | 7 | 19 | 9 | 0 | 20 | 86 |

## Table 4.1b - records removed in Step 9

| source_id | reason | records removed |
|---|---|---|
| DISTRAIN | exact copy within file | 2 |
| DISTRAIN | identical gases, conflicting labels | 4 |
| DISTRAIN | leakage: matches a test record | 139 |

## Table 4.2 - gas medians [ppm] and Kruskal-Wallis test by class, development set

| Gas | Normal median | PD median | D1 median | D2 median | T1 median | T2 median | T3 median | KW H | df | p | epsilon2_R | n |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| H2 | 7.15 | 180.85 | 169.0 | 77.0 | 29.45 | 37.0 | 51.5 | 164.47 | 6 | 6.71e-33 | 0.375 | 439 |
| CH4 | 7.55 | 18.0 | 23.3 | 41.0 | 62.5 | 120.0 | 148.3 | 153.83 | 6 | 1.20e-30 | 0.351 | 439 |
| C2H6 | 1.02 | 11.6 | 9.0 | 16.4 | 108.5 | 81.0 | 58.18 | 191.03 | 6 | 1.54e-38 | 0.436 | 439 |
| C2H4 | 0.78 | 3.5 | 12.67 | 43.0 | 13.3 | 184.6 | 357.0 | 263.95 | 6 | 4.28e-54 | 0.603 | 439 |
| C2H2 | 0.0 | 0.0 | 53.87 | 78.0 | 0.0 | 0.0 | 0.0 | 311.34 | 6 | 3.04e-64 | 0.711 | 439 |

Quartiles (Q1, Q3) for every class are in the CSV file.

## Figures

- Figure 4.1 records per class (4 panels): `11_Results/figures/F4_1_records_per_class.png/.pdf/.csv`
- Figure 4.2 gas concentrations by class (box plots, log scale of concentration + 1 ppm, because not-detected values are 0 ppm under D8): `F4_2_gas_by_class.*`
- Figure 4.3 Spearman correlation between gases: `F4_3_gas_correlation.*`

Check: Table 4.1 totals equal the master table - PASS.
