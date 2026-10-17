# 04 - Conventional DGA Methods in MATLAB

**Purpose.** Objective 1: the IEC 60599 ratio method, the Rogers ratio method (IEEE C57.104-2008 Table 6) and
Duval Triangle 1 as tested MATLAB functions that read every decision limit from `02_Standards/`.
Roadmap Steps 14-17 (MATLAB, finished 11 October 2026). MATLAB R2025b, no toolbox needed for the methods.

**Rules that apply to all files here**
1. No decision limit is typed in the code. All limits come from the CSV files in `02_Standards/` through
   `load_standards.m` (check: `check_no_typed_limits.m`).
2. Every script starts by verifying data version 1.0 (`verify_data_version.m`, SHA-256 of 16 files).
3. Gas columns H2, CH4, C2H6, C2H4, C2H2 in ppm; "not detected" = 0 ppm (decision D8).
4. Decisions D11 to D13 (`00_Project_Admin/decisions_log.md`) fix the implementation rules.

## Files

| File | What it does |
|---|---|
| `conv_config.m` | Paths, gas and ratio names, Rogers case -> class mapping (D11), tap-changer rule, two numerical constants. No limits. |
| `verify_data_version.m` | Recomputes the SHA-256 of every file in `03_Data/data_version_1.0.sha256`; stops if one differs. |
| `load_standards.m` | Reads the IEC Table 2, Rogers Table 6, Duval rules and IEC Table A.2 typical values from `02_Standards/`. |
| `gas_ratios.m` | R1 = CH4/H2, R2 = C2H2/C2H4, R5 = C2H4/C2H6 and the Duval percentages. Zero denominator -> NaN. |
| `duval_xy.m` | Percentages -> plane coordinates of the equilateral triangle (side 1, or 100 for "percentage points"). |
| `bound_test.m` | One printed interval, with the D11 rules for `<`, `>` and printed ranges. |
| `diagnose_ratio_method.m` | IEC or Rogers code table -> class, dual answer (D1/D2) or ND. |
| `diagnose_duval.m` | The 10 Duval rules, first match wins -> PD, T1, T2, T3, DT, D1, D2 or ND. |
| `normality_gate.m` | "Normal" if every gas is at or below the IEC Table A.2 typical value (upper end; lower end = sensitivity). |
| `boundary_distance_ratio.m` | Analysis Plan Eq. 9: distance to the nearest ratio limit in decades. |
| `duval_zone_polygons.m`, `duval_decision_edges.m`, `boundary_distance_duval.m` | Rules -> polygons -> edges between different zones -> Eq. 10 distance in percentage points (D12). |
| `conventional_diagnosis.m` | One call for one or many samples: three methods, gate, boundary distances. Used by the dashboard. |
| `run_conventional_batch.m` | Step 16: all 827 records x 3 methods -> `11_Results/conventional/`. |
| `check_no_typed_limits.m` | Step 14 check: lists every numeric literal in the decision code; passes only for allowed bookkeeping numbers. |
| `plot_duval_triangle.m`, `plot_duval_by_role.m` | Step 17: Duval Triangle 1 with zones, decision edges and points coloured by class (`plot_style.csv`); Figure 4.4. |
| `sanity_check_vs_truth.m` | Plausibility check of the raw outputs against the IEC TC 10 benchmark (not a result). |
| `reduced_gas_diagnosis.m` | Step 26: the three methods when some gases are not measured (removed gases = NaN; a method that needs a removed gas gives ND for every record; gate never passed with a gas missing). Decision D23. |
| `run_reduced_gas_applicability.m` | Step 26: 31 gas combinations x 3 methods x 5 data roles -> `11_Results/conventional/conventional_applicability.csv` (+ `_checks.csv`, 10 automatic checks). |
| `tests/` | `TestConventionalMethods.m` (67 tests, Step 15), `TestReducedGas.m` (26 tests, Step 26), `run_tests_and_log.m`, `test_log.txt`. |

## How to run (MATLAB, from this folder)
```matlab
check_no_typed_limits            % Step 14 check
cd tests; run_tests_and_log      % Steps 15 and 26: 93 tests (67 + 26), writes tests/test_log.txt
cd ..; run_conventional_batch    % Step 16: writes 11_Results/conventional/*.csv
plot_duval_by_role               % Step 17: writes 11_Results/figures/duval_<role>.png/.pdf/.csv
run_reduced_gas_applicability   % Step 26: writes 11_Results/conventional/conventional_applicability.csv (+ _checks.csv)
```
One sample: `d = conventional_diagnosis(struct('H2',270,'CH4',190,'C2H6',4,'C2H4',17,'C2H2',5))`.

## Rules in short (full text: decisions D11 and D12)
- Each interval: `<` and `>` strict; printed ranges "a - b" include both end points; "NS" entries are not used.
- A class matches only if every ratio it USES is defined (denominator not 0) and inside its interval. No match -> `ND`.
- Several IEC classes match -> joined with "/" (only `D1/D2` occurs). IEC T1 requires CH4/H2 > 1 (decision D13), so PD and T1 never overlap.
- Duval: lower limit inclusive, upper limit exclusive, first rule in `rule_order` wins; `DT` is a valid zone.
- Final result = `Normal` if the upper normality gate is passed, otherwise the method's own result (`raw_result`).
- Rogers cases 0..5 -> Normal, PD, D2, T1, T2, T3 (Rogers has no D1 case).

## Known limits (see the Step 14-17 reports)
- Duval, Rogers and IEC limits are TO VERIFY against primary sources (see `02_Standards/sources.md`).
- D13 (T1 requires CH4/H2 > 1) departs slightly from the printed IEC table, which marks that entry "NS"; it raises IEC "no diagnosis" from 204 to 319 records (raw).
- The normality gate is the researcher's design; IEC Annex A says the typical values are not fault limits.

**Acceptance criteria (met 11 Oct 2026).** `runtests` passes (67/67); MATLAB and Python are to agree on 100 % of
records (Step 18); "no diagnosis" counts reported per method.

**Feeds thesis.** Chapter 3 (conventional layer), Chapter 4 (conventional-method results, Figure 4.4).




## Step 26 - gases removed (decision D23)
- A removed gas is **NaN (not measured), never 0 ppm** (0 ppm means measured, not detected: D8).
- IEC 60599 and Rogers need all five gases (every gas in R1, R2, R5), Duval needs CH4, C2H4, C2H2. A method that needs a removed gas returns **ND for every record**, decided before any ratio, zone or gate test. The required gases are derived in `conv_config.m` (`requiredGas`), not typed per method.
- Normality gate on incomplete data: Normal only if all five gases are measured (D23 rule 4, proposed). The sensitivity (gate on the measured gases only) is the column `n_nd_gate_measured`.
- Only `conv_config.m` (new fields `duvalGas`, `requiredGas`, `roles`) and `tests/run_tests_and_log.m` (runs both test classes) were changed; no rule of Steps 14-17 was changed. Fingerprints: `code_manifest_step26.sha256` (`code_manifest.sha256` stays the record of Steps 14-17).
