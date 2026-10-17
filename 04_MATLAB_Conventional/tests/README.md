# tests - unit tests of the conventional DGA methods (Roadmap Step 15)

| File | Purpose |
|---|---|
| `TestConventionalMethods.m` | `matlab.unittest` class with 67 tests (see below). |
| `TestReducedGas.m` | Step 26: 26 tests of the rule for removed gases (see the end of this file). |
| `run_tests_and_log.m` | Runs the class with `runtests` and writes `test_log.txt` (date, MATLAB version, full output, one line per test). Raises an error if any test fails. |
| `test_log.txt` | Log of the last run. |

**Run:** `cd tests; run_tests_and_log` (about 15 s; runs both classes, 93 tests).

## What the 67 tests check
- (a) **Worked examples (41 tests).** 40 tests, one per row of `02_Standards/worked_examples.csv`: 39 Duval Triangle 1
  examples (Aciu et al. 2021; Manisha et al. 2022) and the IEEE C57.104-2008 Figure 2 Rogers example (Case 2), compared with
  the printed diagnosis. The method output BEFORE the normality gate is tested (the gate is a project rule, not part of the
  published examples). Plus one test that the file really contains 39 + 1 examples.
- (b) **Zero denominators (6).** Undefined ratio -> NaN; zero numerator is a valid ratio 0; Rogers and IEC give ND when a
  needed ratio is undefined; an undefined NS ratio does not stop PD (decision D12); Duval with CH4 = C2H4 = C2H2 = 0 -> ND.
- (c) **Boundary samples (7).** Ratios exactly on a limit follow D11: `<`/`>` strict, printed ranges include both end points;
  Duval lower limit inclusive, upper limit exclusive; T1 requires CH4/H2 > 1 (D13).
- (d) **Normality gate (3).** Upper end, lower end, tap-changer rule for C2H2, same gate for all three methods.
- (e) **Structure (10).** Duval polygons cover the triangle exactly once (area 5000); every grid point has a zone; Rogers cases
  never overlap; the only IEC overlap is D1/D2; boundary distances (decades, percentage points, triangle sides and
  seams not counted); frozen data version verifies; batch gives 827 x 3 rows with ND kept; no typed limits in the code.

Gas values used to build boundary samples are chosen so that the ratio is exactly equal to a limit; every limit used for a
comparison is read from `02_Standards` (none is typed in a test).



## TestReducedGas (Step 26, 26 tests)
- (a) one removed gas, any of the five (5 tests) -> IEC 60599 and Rogers give ND for every record, raw and final; plus one test that without the rule the same records do get a class (the test is not vacuous).
- (b) Duval ignores H2 and C2H6 (1 test); removing any of CH4, C2H4, C2H2 gives ND for every record (3 tests).
- (c) values of removed gases are ignored: 0, 1e9 and NaN give identical output (1 test).
- (d) five gases present = `conventional_diagnosis` of Steps 14-17, raw and final (1 test).
- (e) the gate is never passed with a gas missing (5 tests) and the sensitivity gate is never stricter than the primary gate (5 tests).
- (f) unknown gas name raises an error; required gases come from `conv_config`; the batch passes its 10 checks and gives 31 x 3 x 5 rows; the 'no typed limits' audit still passes with the new files (3 + 1 tests).
