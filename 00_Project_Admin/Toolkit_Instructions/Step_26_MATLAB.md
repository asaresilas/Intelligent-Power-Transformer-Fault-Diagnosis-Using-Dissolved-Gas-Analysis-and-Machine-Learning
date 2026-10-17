# Roadmap Step 26 [MATLAB] - run the conventional methods with gases removed

Prepared 12 October 2026 (Claude Code). Use either the MATLAB Agentic Toolkit or the MATLAB MCP connection of Claude Code (decision D14).

## Inputs
- `03_Data/processed/dga_master.csv` (data version 1.0 - call `verify_data_version` first)
- `11_Results/reduced_gas/reduced_gas_subsets.csv` (31 gas combinations; columns `subset_id`, `has_H2` ... `has_C2H2`)
- The existing functions in `04_MATLAB_Conventional/` (do not change their rules; decisions D11-D13 stay in force)

## Rule to apply (Analysis Plan Section 8, last paragraph - proposed as decision D23)
"The Rogers and IEC 60599 ratios need all five gases, and Duval Triangle 1 needs CH4, C2H4 and C2H2; if any of these is missing
the method gives ND." So, for each combination:
1. Set the removed gases to NaN (missing - NOT 0 ppm; 0 ppm means "measured, not detected", decision D8).
2. A method whose required gases are not all present returns **ND** for every record - before any ratio, zone or normality-gate
   test is applied (no partial use of the IEC table under D12, no Normal from the gate on incomplete data).
3. Otherwise run the method exactly as in Steps 14-17 (`run_conventional_batch` logic, upper normality gate).

## Do
For every combination and every method (IEC 60599, Rogers, Duval), over all 827 records and also per data role:
- n_records, n_ND, share_ND, n_diagnosed, and whether the method is applicable (required gases present).

## Output
`11_Results/conventional/conventional_applicability.csv` with columns
`subset_id, n_gases, method, applicable, data_role, n_records, n_nd, share_nd`
(data_role = all / development / internal_test / benchmark / external_test).

## Checks (roadmap)
- A method that needs a removed gas returns ND for 100 % of records, never a guess.
- For the five-gas combination the ND counts equal those of `11_Results/conventional/conventional_counts.csv` (Steps 14-17).
- For a combination that keeps CH4, C2H4 and C2H2, the Duval ND count equals the five-gas Duval ND count.
- Add a unit test to `04_MATLAB_Conventional/tests/` for rule 2 (one removed gas -> ND for IEC and Rogers).

## Tell the toolkit
"For each subset in reduced_gas_subsets.csv, set the removed gases to NaN, return ND for any method that needs a removed gas
(IEC 60599 and Rogers need all five gases, Duval needs CH4, C2H4 and C2H2), otherwise run the batch diagnosis as in Steps 14-17,
and save the share of ND per method and data role in 11_Results/conventional/conventional_applicability.csv. Check that the
five-gas row reproduces conventional_counts.csv."
