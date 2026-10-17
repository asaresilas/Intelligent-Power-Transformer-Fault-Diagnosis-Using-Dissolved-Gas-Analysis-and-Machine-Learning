# Instructions for the MATLAB Agentic Toolkit — Roadmap Steps 14 to 17 (conventional DGA methods)

Prepared 11 October 2026 by Claude Code after Step 13 (data version 1.0 frozen). Do the steps strictly in order.
Before Step 14, Steps 2 and 3 (toolkit set-up) must be finished, and their logs sent back to Claude Code for checking.

## Rules that apply to every step

1. **Read, never type, limits.** Every threshold comes from the frozen files in `02_Standards/`
   (`iec_ratio_table.csv`, `iec_typical_values.csv`, `duval_triangle_zones.csv`, `rogers_ratio_table.csv`,
   `worked_examples.csv`). No numeric limit may appear in the `.m` code.
2. **Use only data version 1.0.** At the start of every script, recompute the SHA-256 of each file listed in
   `03_Data/data_version_1.0.sha256` and stop with an error if any differs.
3. **Gas columns and units:** `H2, CH4, C2H6, C2H4, C2H2` in ppm, from `03_Data/processed/dga_master.csv`
   (not detected = 0 ppm, decision D8). Keep `record_id` in every output.
4. **Decision D11 (approved 2026-10-11)** fixes the implementation rules:
   - Normality gate (all three methods): result = Normal if every gas ≤ the **upper** end of its range in
     `iec_typical_values.csv`. Also produce a sensitivity column with the **lower** end.
   - C2H2 typical range: "Communicating OLTC" row only when `equipment_type` = `U` (IEC TC 10 records);
     "No OLTC" row for every other record.
   - Printed ranges with `bound_type` = `range_endpoints_not_stated` include both end points; `lt` and `gt` are strict;
     `gt_lt` is strict on both sides; `ns` / `gt_but_ns` ratios are ignored.
   - IEC: if a sample satisfies both D1 and D2, output `D1/D2` (dual attribution, IEC 60599 clause 5.3).
   - Rogers case → class: 0 Normal, 1 PD, 2 D2, 3 T1, 4 T2, 5 T3. Ratios R1 = CH4/H2, R2 = C2H2/C2H4, R5 = C2H4/C2H6.
   - Duval Triangle 1: apply the rules of `duval_triangle_zones.csv` in `rule_order`; lower limit inclusive (≥), upper
     limit exclusive (<); first matching rule wins. DT is a valid output.
   - A ratio with a zero denominator is undefined → that method gives `ND` (no diagnosis). If no rule/case/zone
     matches → `ND`. ND is a result: never remove it.
5. **Annotate** every function (purpose, inputs, outputs, source table and clause) and keep figures to
   `11_Results/figures/plot_style.csv` (colours and markers).

## Step 14 — Complete the conventional-method functions

**Tell the toolkit:**
> In `04_MATLAB_Conventional`, extend `gas_ratios.m`, `duval_xy.m` and `conventional_diagnosis.m` so that every limit is read
> from the CSV files in `02_Standards` (no numbers typed in code). Implement the IEC 60599 ratio method
> (`iec_ratio_table.csv`, Table 2 rows only; the "simplified scheme" rows are not used), the Rogers ratio method
> (`rogers_ratio_table.csv`) and Duval Triangle 1 (`duval_triangle_zones.csv`), following decision D11 in
> `00_Project_Admin/decisions_log.md` and the rules in `00_Project_Admin/Toolkit_Instructions/Steps_14-17_MATLAB.md`.
> Add the normality gate from `iec_typical_values.csv` (upper end primary, lower end sensitivity). Return ND when no rule
> applies or a ratio is undefined. Compute each sample's distance to the nearest decision boundary as in the Analysis
> Plan, Section 4.5: for the ratio methods d_R = min over ratios and limits of |log10(R) − log10(L)|; for Duval the
> shortest distance in percentage points from the sample point to the nearest zone-limit line that borders its zone.
> Add a batch function that reads `03_Data/processed/dga_master.csv` after verifying `data_version_1.0.sha256`.

**Check:** no threshold typed in code (search the `.m` files for numeric literals used as limits).

## Step 15 — Unit-test the conventional methods

**Tell the toolkit:**
> Create a `matlab.unittest` test class in `04_MATLAB_Conventional/tests` that (a) reproduces every row of
> `02_Standards/worked_examples.csv` (39 Duval Triangle 1 examples and 1 Rogers example: Case 2), (b) checks zero
> denominators give ND, (c) checks samples exactly on a boundary follow decision D11, and (d) checks the normality gate.
> Run `runtests` and save the log as `04_MATLAB_Conventional/tests/test_log.txt`.

**Check:** every test passes. (Python already reproduces all 40 examples from the same tables — Step 12 check.)

## Step 16 — Run the three methods on every record

**Tell the toolkit:**
> Run the batch conventional diagnosis on all 827 records of `dga_master.csv` and write
> `11_Results/conventional/conventional_predictions.csv` with one row per record and method and the columns:
> `record_id, method (IEC60599 | Rogers | Duval), gate_upper (Normal or blank), gate_lower (Normal or blank),
> raw_result (class code, D1/D2, DT or ND, before the gate), result (after the upper gate), ratio_R1, ratio_R2,
> ratio_R5 (or pct_CH4, pct_C2H4, pct_C2H2 for Duval), boundary_distance, data_version (1.0)`.
> Report the number of ND, DT and D1/D2 results per method and data role.

**Check:** exactly 827 × 3 rows; ND rows kept; counts reported.

## Step 17 — Plot the Duval Triangles

**Tell the toolkit:**
> Use `plot_duval_triangle.m` to draw Duval Triangle 1 for each data role (development, internal test, IEC TC 10
> benchmark, external test). Draw the zones from `duval_triangle_zones.csv`, and colour and shape each sample by its true
> class using `11_Results/figures/plot_style.csv`. Save `11_Results/figures/duval_<role>.png` (300 dpi) and `.pdf`,
> with the plotted points as `duval_<role>.csv` (Figure 4.4).

**Check:** zone lines match the 10 rules of the CSV; figures made by script.

## Hand-back to Claude Code

Send back: the updated `.m` files, `tests/test_log.txt`, `conventional_predictions.csv`, the four Duval figures, and the
toolkit's session log. Claude Code then writes the Step 14–17 reports and does **Step 18**: re-implements the three
methods in Python from the same tables and checks that MATLAB and Python agree on 100 % of records.


## Corrections found while the steps were carried out (11 October 2026) - read these before reusing the instructions
The instructions above were tested on the real data. Three rules were amended by the researcher (decision D12 in `00_Project_Admin/decisions_log.md`),
and four practical points were found. Details and numbers: Step 14 Report.

1. **Rule 4, last bullet (zero denominator).** Now: a class matches only if every ratio that the table USES for that class is defined; a ratio marked
   "NS" (not significant) is not used, so an undefined NS ratio does not give ND. (IEC ND 239 -> 204 of 827 records.)
2. **Rule 4, IEC dual attribution.** If T1 ignored CH4/H2 (printed ">1 but NS"), PD and T1 would match together (27 records) and IEC could never answer PD alone.
   Decision D13: the printed ">1" is used as the condition CH4/H2 > 1 for T1 (strict). PD and T1 no longer overlap; only D1/D2 remains a dual answer.
   Effect: IEC raw ND 204 -> 319 of 827 records.
3. **Step 14, boundary distance for Duval.** Analysis Plan Eq. 10 is applied to the edges that separate two DIFFERENT zones only (not the triangle sides, not the
   seams inside one zone), as a Euclidean distance in percentage points (triangle of side 100).
4. **Step 15 (a).** The worked examples are tested on the method result BEFORE the normality gate (examples MAN-22 and MAN-23 lie below the gate).
5. **Existing stubs.** The old `gas_ratios.m`, `duval_xy.m`, `conventional_diagnosis.m` and `plot_duval_triangle.m` expected other CSV layouts and were rewritten
   (the names and the dashboard calls are kept).
6. **Step 17.** Points are plotted without the gate; the 32 inspected T1/T2 records (no `class_name`) use `class_merged = T12`.
7. **Toolkit set-up.** Steps 2 and 3 were not finished; Steps 14-17 were run with the MATLAB MCP connection of Claude Code. Accepted by the researcher (decision D14).