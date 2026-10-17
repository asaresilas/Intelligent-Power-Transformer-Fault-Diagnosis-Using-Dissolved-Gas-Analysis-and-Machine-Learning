# 11_Results/conventional - output of the conventional DGA methods (Roadmap Step 16)

Produced by `04_MATLAB_Conventional/run_conventional_batch.m` on data version 1.0 (11 October 2026). Do not edit by hand.

| File | Content |
|---|---|
| `conventional_predictions.csv` | 2481 rows = 827 records x 3 methods (IEC60599, Rogers, Duval). Columns: `record_id, method, gate_upper, gate_lower, raw_result, result, ratio_R1, ratio_R2, ratio_R5, pct_CH4, pct_C2H4, pct_C2H2, boundary_distance, data_version`. |
| `conventional_counts.csv` | Per method and data role: n, gate counts, and the numbers of ND, DT, D1/D2 and PD/T1 results after the gate (`*_final`) and before it (`*_raw`). |
| `no_typed_limits_audit.csv` | Step 14 check: disallowed numeric literals in the decision code (empty = pass). |
| `conventional_applicability.csv` | Step 26: 465 rows = 31 gas combinations x 3 methods x 5 data roles (all, development, internal_test, benchmark, external_test). Columns: `subset_id, n_gases, method, applicable (1/0), data_role, n_records, n_nd, share_nd`, then `n_diagnosed, n_nd_raw, n_nd_gate_measured`. A method that needs a removed gas has `share_nd` = 1. ND counts are after the gate (like `ND_final`). `n_nd_gate_measured` is the sensitivity of D23 rule 4. |
| `conventional_applicability_checks.csv` | The 10 automatic checks of Step 26 (all must pass). |
| `sanity_agreement_benchmark.csv` | Plausibility check against the IEC TC 10 benchmark. Not a result. |

## Columns of `conventional_predictions.csv`
- `gate_upper`, `gate_lower`: "Normal" when every gas is at or below the upper / lower end of its IEC 60599 Table A.2 range
  (decision D11), otherwise blank.
- `raw_result`: the method's own answer before the gate: class (PD, D1, D2, T1, T2, T3), Rogers case mapped to a class,
  dual answer (`D1/D2`; `PD/T1` no longer occurs since decision D13), `DT` (Duval) or `ND` (no diagnosis).
- `result`: after the upper gate: "Normal" if `gate_upper` is "Normal", otherwise `raw_result`.
- `ratio_R1`, `ratio_R2`, `ratio_R5` = CH4/H2, C2H2/C2H4, C2H4/C2H6 (NaN = zero denominator; blank for Duval rows).
- `pct_CH4`, `pct_C2H4`, `pct_C2H2`: Duval percentages (NaN when all three gases are 0 ppm; blank for the ratio methods).
- `boundary_distance`: IEC and Rogers: decades of the ratio (Analysis Plan Eq. 9); Duval: percentage points (Eq. 10, D12).
  `Inf` = every defined ratio is 0; NaN = no ratio defined.
- `data_version`: 1.0.
ND rows are kept. Cross-check by Python: roadmap Step 18.

