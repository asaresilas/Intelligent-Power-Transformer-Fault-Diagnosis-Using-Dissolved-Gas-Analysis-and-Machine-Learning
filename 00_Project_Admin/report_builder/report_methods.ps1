# report_methods.ps1 - the "Method used" section of every step report (report standard, 2026-10-10).
# Each entry: Approach (paragraphs), Why (bullets), Settings (table rows), Eqs (equation + where-list), Tools, Refs (register IDs).

$global:Methods = @{
"1" = @{
  Approach = @("An isolated software environment was built: the official Python interpreter was installed, a private 'virtual environment' was created for this project only, the required libraries were installed into it, and the exact version of every installed package was frozen in a list. A short test program then imported every library to prove the environment works.")
  Why = @(
    "Results can only be reproduced if the same software versions are used; a frozen version list (requirements.txt) lets anyone rebuild the identical environment.",
    "A private environment keeps the project's libraries separate from anything else on the computer, so other software cannot change the results.",
    "Testing every import immediately finds installation problems before any data work starts.")
  Settings = @(
    @("Python version", "3.12.10 (official installer, installed with winget; installer fingerprint verified by winget)"),
    @("Environment location", "06_Python_ML/.venv"),
    @("Libraries required by the roadmap", "16 (plus pyyaml and httpx)"),
    @("Packages frozen", "55, with exact versions, in 06_Python_ML/requirements.txt"),
    @("How programs are run", "python -I <program> (isolated mode: ignores user-wide settings, so only the project environment is used)"))
  Tools = @("winget; python -m venv; pip install / pip freeze", "06_Python_ML/src/check_environment.py (imports every library and prints its version)")
  Refs = @()
}
"4" = @{
  Approach = @("Pre-specification: every analysis choice - which data play which role, which measures and statistical tests are used, the tolerances and the figures - was written into the Expected Results and Analysis Plan and approved before any data were analysed. Any later change is allowed only as a numbered decision with its evidence in the decision log.")
  Why = @(
    "Fixing the methods before seeing the results prevents choosing, consciously or not, the method that gives the best-looking result.",
    "A written decision log lets supervisors, examiners and reviewers check that every change was justified by evidence (as for D8 and D9).")
  Settings = @(
    @("Items approved", "18 analysis-plan items (Section 14 of the Analysis Plan)"),
    @("Decisions handled", "D1-D7 (D5 left open); later D8, D9, D10 added with evidence"),
    @("Approver", "The researcher (supervisor sign-off not yet recorded)"))
  Tools = @("00_Project_Admin/Expected_Results_and_Analysis_Plan.docx; Project_Roadmap.docx; decisions_log.md")
  Refs = @()
}
"5" = @{
  Approach = @(
    "Integrity check: the SHA-256 fingerprint of every raw file was calculated and compared with the value recorded at download.",
    "Faithful reading: every file was read as plain text, so that the reading software could not silently change any value (for example, turn an empty cell into a number). Values were then converted to numbers one by one, and any value that could not be converted was reported.",
    "Standardisation: the columns were renamed and put into one shared order, every record received a unique identifier and the line number in its source file, and every re-ordered cell was compared with the original.")
  Why = @(
    "Checking fingerprints proves that the data analysed are exactly the published data (data integrity).",
    "Keeping the source line number makes every record traceable to its origin, which is needed to find copies later (Step 9).",
    "Converting values explicitly, rather than trusting automatic conversion, means no value is changed without being reported.")
  Settings = @(
    @("Gas order", "H2, CH4, C2H6, C2H4, C2H2 (unit: ppm)"),
    @("Record identifier", "SOURCE_NNNN, e.g. DISTRAIN_0001, plus source file and line number"),
    @("Empty cells", "kept as missing - never replaced in this step"),
    @("Impossible values checked", "negative numbers and text that is not a number"),
    @("Fingerprint algorithm", "SHA-256"))
  Tools = @("06_Python_ML/src/data_prep/step05_standardise.py", "pandas 3.0.6 (read_csv / read_excel with dtype=str and keep_default_na=False; openpyxl 3.1.5 for Excel); Python hashlib for SHA-256")
  Refs = @("M1")
}
"6" = @{
  Approach = @(
    "Missing-data audit: every gas cell was put into one of four groups - measured (a positive value), zero, placeholder (exactly 0.0001) or blank. The groups were counted for every source, gas and fault class.",
    "Impact analysis: for each fault class, the number of records that would be left if incomplete records were thrown away was calculated.",
    "Mechanism check: the pattern of missing gases was compared with how faults produce gases (IEC 60599, clause 4.1), to judge whether 'missing' means 'not detected'.")
  Why = @(
    "How missing values are treated can change the results, so the choice must be based on why the values are missing, not made by habit.",
    "Throwing away incomplete records is only safe when missingness has nothing to do with the fault class. Here it depends strongly on the class (acetylene is missing in most T1 records), so deleting would have removed almost a whole class and biased every comparison.",
    "Keeping a flag on every record lets the alternative choice (complete records only) be run as a sensitivity analysis.")
  Settings = @(
    @("Placeholder value", "exactly 0.0001 ppm"),
    @("Primary rule (decision D8)", "not available (blank or placeholder) = not detected = 0 ppm"),
    @("Flags kept on each record", "n_blank, n_placeholder, n_zero, all_five_reported"),
    @("Sensitivity analysis", "records with all five gases reported (complete cases)"))
  Tools = @("06_Python_ML/src/data_prep/step06_missing_values.py (pandas 3.0.6)")
  Refs = @("ST1")
}
"7" = @{
  Approach = @("Label harmonisation with an explicit translation table (label map): one row for every original label in every file, giving the new class code, the reason and the evidence. The table is applied automatically to every record; a label that is not in the table stops the program.")
  Why = @(
    "All methods must be judged against the same class definitions; the definitions follow IEC 60599, clause 5.2.",
    "A written table with reasons makes every translation open to checking, instead of being hidden inside code.",
    "Where a source cannot separate two classes (T1 and T2 in IEC TC 10), they are merged (T12) rather than guessed.")
  Settings = @(
    @("Fine scheme", "0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3"),
    @("Merged scheme", "T1 and T2 joined as T12 (used for the IEC TC 10 benchmark)"),
    @("Rows in the label map", "33 (7 for each Dissanayake file, 5 IEC TC 10, 7 Li 2019)"),
    @("Unknown labels", "not allowed - the program stops"))
  Tools = @("06_Python_ML/src/data_prep/step07_label_map.py (pandas 3.0.6); output 03_Data/processed/label_map.csv")
  Refs = @("ST1", "DS1")
}
"8" = @{
  Approach = @("Inclusion criteria applied by flagging: each IEC TC 10 case keeps all its data but receives a flag 'in scope for the primary analysis' and a reason, based on its equipment code. Nothing is deleted.")
  Why = @(
    "The thesis makes claims about power transformers, so the main comparison must use power transformers only (approved plan item 8).",
    "Flagging instead of deleting keeps every record for the sensitivity analysis and allows a full count (kept + excluded = total).")
  Settings = @(
    @("Included (primary)", "equipment codes P and U - power transformers without / with a communicating on-load tap changer"),
    @("Excluded from primary, kept for sensitivity", "R reactor, I instrument transformer, B bushing, C cable, S selector compartment, blank code"),
    @("Record of exclusions", "03_Data/interim/exclusion_log.csv"))
  Tools = @("06_Python_ML/src/data_prep/step08_scope_filter.py (pandas 3.0.6)")
  Refs = @("DS1")
}
"9" = @{
  Approach = @(
    "Record linkage by rules fixed in advance. Gas values were first harmonised with decision D8. Two records were called an exact match if all five gases are equal (rounded to 4 decimals), and a near match if every gas differs by no more than the tolerance in Equation 1.",
    "Within each file, exact copies were reduced to the first one; if identical gases carried different labels, all copies were removed. Across files, every record was compared with every other record. A training record that matches any test record (exactly or nearly) was removed from training. Overlaps between test sets were flagged, not removed.",
    "Where a training or test record copies an IEC TC 10 case, its label was compared with the inspection label (label-agreement analysis).")
  Why = @(
    "If a test case is also in the training data, the model has seen the answer and its score is falsely high. Such leakage is a documented cause of irreproducible machine-learning results (Kapoor and Narayanan, 2023).",
    "The near-match rule also catches copies that differ only by rounding or by the 0.0001 placeholder.",
    "Comparing labels with inspection results measures how trustworthy each dataset's labels are.")
  Settings = @(
    @("Relative tolerance", "1 % of the larger value"),
    @("Absolute tolerance", "1 ppm"),
    @("Exact match", "all five gases equal after rounding to 4 decimals"),
    @("Duplicates within a file", "keep the first (lowest source line); remove all if labels conflict"),
    @("Overlaps between test sets", "flagged (decision D9), never removed"))
  Eqs = @(
    @{ Eq = "|a_g-b_g|≤max(1`" ppm`",0.01⋅max(|a_g|,|b_g|)){SP}`"for every gas `"g"; Where = @(
        @("a_g, b_g", "concentration of gas g in the two records being compared [ppm]"),
        @("g", "each of the five gases H2, CH4, C2H6, C2H4, C2H2")) })
  Tools = @("06_Python_ML/src/data_prep/step09_dedup_leakage.py (numpy 2.5.3 pairwise comparison, pandas 3.0.6)", "06_Python_ML/tests/test_no_leakage.py (pytest 9.1.1, 5 automated tests)")
  Refs = @("M2")
}
"10" = @{
  Approach = @(
    "Repeated stratified group k-fold cross-validation. First, groups of near-identical training records were found: two records belong to the same group if they are near matches (Equation 1 of Step 9), and groups are joined through chains of near matches (connected components, found with a union-find algorithm).",
    "The training data were then split into 5 folds so that every fold has the same mix of the 7 classes (stratified) and each group stays inside one fold (group). The split was repeated 10 times with different, recorded random seeds.")
  Why = @(
    "Stratification keeps rare classes present in every fold, which matters because the classes are unequal in size.",
    "Keeping near-copies in one fold prevents leakage inside the cross-validation itself.",
    "Ten repeats reduce the effect of one lucky or unlucky split and give 50 paired scores per model, which the planned statistical comparisons need.",
    "Fixed, recorded seeds make the splits exactly repeatable.")
  Settings = @(
    @("Folds x repeats", "5 x 10 = 50 train/test splits"),
    @("Stratified by", "fine class code 0-6"),
    @("Random seed", "20261010 + r for repeat r = 1 ... 10 (seeds 20261011 to 20261020)"),
    @("Near-duplicate tolerance", "same as Step 9 (1 % or 1 ppm on every gas)"),
    @("Records split", "439 development records"))
  Tools = @("06_Python_ML/src/data_prep/step10_folds.py (scikit-learn 1.9.1 StratifiedGroupKFold with shuffle=True)", "06_Python_ML/tests/test_folds.py (pytest 9.1.1, 4 automated tests)")
  Refs = @("M3", "M2")
}
"11" = @{
  Approach = @(
    "Descriptive statistics: the median and the first and third quartiles of every gas in every fault class.",
    "Kruskal-Wallis H test for each gas: does the gas differ between the 7 fault classes? The test works on ranks, so it does not assume normally distributed data. The size of the difference is given by the effect size epsilon-squared.",
    "Spearman rank correlation between every pair of gases.",
    "Figures drawn by program with the shared style file: bar charts of class counts, box plots on a logarithmic axis, and a correlation heat map.")
  Why = @(
    "Gas concentrations are very skewed and contain many zeros, so rank-based methods are more appropriate than methods that assume a normal distribution.",
    "With 439 records even small differences give tiny p-values, so the effect size is reported to show how large each difference really is.",
    "Drawing all figures from saved data with one style file makes them reproducible and consistent across Python and MATLAB.")
  Settings = @(
    @("Data", "development set, N = 439 records, k = 7 classes (degrees of freedom k - 1 = 6)"),
    @("Ties", "the H statistic is corrected for tied values (SciPy default)"),
    @("Box plots", "whiskers at 1.5 times the interquartile range; axis = concentration + 1 ppm, log scale"),
    @("Figure files", "PNG at 300 dpi and PDF, Arial 9 pt, with the plotted numbers saved as CSV"))
  Eqs = @(
    @{ Eq = "H=12/(N(N+1)) ∑_(i=1)^k (R_i^2)/n_i -3(N+1)"; Where = @(
        @("H", "Kruskal-Wallis statistic (before the tie correction)"),
        @("N", "total number of records (439)"),
        @("k", "number of classes (7)"),
        @("n_i", "number of records in class i"),
        @("R_i", "sum of the ranks of the records in class i, when all N values of the gas are ranked together")) },
    @{ Eq = "ε_R^2=H(N+1)/(N^2-1)"; Where = @(
        @("ε_R^2", "effect size, from 0 (no difference) to 1 (classes completely separated)"),
        @("", "Same formula as Equation 24 of the Analysis Plan and as coded in step11_describe.py.")) },
    @{ Eq = "ρ_s=r(`"rank`"(x),`"rank`"(y))"; Where = @(
        @("ρ_s", "Spearman rank correlation between gases x and y, from -1 to +1"),
        @("r", "the ordinary (Pearson) correlation, applied to the ranks")) })
  Tools = @("06_Python_ML/src/analysis/step11_describe.py and plotstyle.py", "SciPy 1.18.1 (stats.kruskal), pandas 3.0.6 (corr, method='spearman'), numpy 2.5.3 (percentiles), matplotlib 3.11.2 (figures)")
  Refs = @("M4", "M5", "M6", "M7")
}
"12" = @{
  Approach = @(
    "Document analysis with double-entry transcription: the decision tables were copied from the primary source where one was available (official previews of IEC 60599) and typed a second time, independently, into a checking program that compares both entries automatically.",
    "Edition tracing: the official lists of technical changes of the 2015 and 2022 editions were used to judge whether the 2007 tables are still current.",
    "Triangulation: each table was compared with independent secondary sources. Where they disagreed (Rogers), neither was used; the conflict was resolved from the standard itself (IEEE Std C57.104-2008, Table 6).",
    "Validation of the Duval zones: the rules were tested on a fine grid covering the whole triangle (every point must fall in exactly one zone), and on every worked example whose diagnosis is printed in a published paper.")
  Why = @(
    "Copying numbers by hand is error-prone; entering them twice and comparing automatically is a standard way to catch transcription errors.",
    "Using the standard itself (primary source) is required for publication; secondary sources are only accepted with agreement checks and a TO VERIFY mark.",
    "The grid test proves that the zone rules have no gaps or overlaps, and the worked examples prove they reproduce published diagnoses.")
  Settings = @(
    @("Grid for the Duval test", "0.1 % steps - 501 501 points"),
    @("Zone limits", "lower limit included (>=), upper limit excluded (<); PD checked first"),
    @("Worked examples", "40 (Duval: Aciu et al. 3, Manisha et al. 36; Rogers: IEEE C57.104-2008 Figure 2); blank gas = 0 ppm (D8)"),
    @("Rogers ratios", "R1 = CH4/H2, R2 = C2H2/C2H4, R5 = C2H4/C2H6; printed ranges without stated end points taken as inclusive for the check (the final rule is fixed in Step 14)"),
    @("Second entry", "every value typed again in step12_check_tables.py"))
  Eqs = @(
    @{ Eq = "%CH_4=100⋅CH_4/(CH_4+C_2 H_4+C_2 H_2 )"; Where = @(
        @("CH_4, C_2 H_4, C_2 H_2", "concentrations of methane, ethylene and acetylene [ppm]"),
        @("", "%C2H4 and %C2H2 are calculated the same way; the three percentages add up to 100 and fix one point in the Duval Triangle 1.")) })
  Tools = @("06_Python_ML/src/standards/step12_check_tables.py (numpy 2.5.3, pandas 3.0.6)")
  Refs = @("ST1", "ST2", "ST3", "ST5", "P1", "P2", "P3", "P4")
}
"13" = @{
  Approach = @(
    "Content fingerprinting: the SHA-256 fingerprint of every file that later steps depend on - the raw data, the processed tables, the standards tables and the figure-style file - was calculated and written into one list (a 'manifest') named after the data version.",
    "Enforcement: a check function (verify_data_version) recalculates every fingerprint and compares it with the manifest; every later step must call it before reading the data, and an automated test does the same.",
    "Flow figure: Figure 3.2 shows how many records entered, were removed and ended in each data role. Every number is calculated from the files, and the program stops if the numbers do not add up.")
  Why = @(
    "Freezing the data means every later result can be traced to exactly these files; if any file changes, even by one character, the check fails at once.",
    "Recording the fingerprints is the standard way to prove that the analysed data are the data described in the thesis (data integrity and reproducibility).",
    "A flow figure with counts lets readers see where every record went, as reporting guidelines for data preparation recommend; computing it from the files and checking that the counts add up prevents typing errors.")
  Settings = @(
    @("Data version", "1.0 (11 October 2026)"),
    @("Files frozen", "16: 5 raw data files, 3 processed tables, 7 standards tables, 1 figure-style file"),
    @("Manifest", "03_Data/data_version_1.0.sha256 (sha256sum format: fingerprint, two spaces, file path)"),
    @("Rule from now on", "a frozen file changes only through a new, recorded data version (e.g. 1.1)"),
    @("Count checks in Figure 3.2", "development = training file - removed; master = development + three test roles; folds cover the development set"))
  Tools = @("06_Python_ML/src/data_prep/step13_freeze.py; common.verify_data_version()", "Python hashlib (SHA-256), pandas 3.0.6, matplotlib 3.11.2 (Figure 3.2); tests/test_data_version.py (pytest 9.1.1)")
  Refs = @("M1")
}
}

function MethodSection([string]$step) {
  $m = $global:Methods[$step]
  H1N "Method used"
  H2 "Approach"
  foreach ($a in $m.Approach) { Body $a }
  H2 "Why this method"
  foreach ($w in $m.Why) { Bullet $w }
  H2 "Settings and rules"
  $rows = @(); foreach ($s in $m.Settings) { $rows += , @($s[0], $s[1]) }
  AddTable @("Setting", "Value") $rows @(150, 300)
  if ($m.Eqs) {
    H2 "Equations"
    foreach ($e in $m.Eqs) { Eq $e.Eq; WhereList $e.Where }
  }
  H2 "Tools and programs"
  foreach ($t in $m.Tools) { Bullet $t }
  if ($m.Refs.Count -gt 0) {
    H2 "Method references"
    $reg = Import-Csv $global:RegisterCsv -Encoding UTF8
    foreach ($id in $m.Refs) {
      $e = $reg | Where-Object { $_.id -eq $id }
      $l = if ($e.doi) { " doi: " + $e.doi } else { " " + $e.link }
      $note = if ($e.notes -like "TO VERIFY*") { " [" + $e.notes + "]" } else { "" }
      Ref ("[" + $id + "] " + $e.reference + $l + $note)
    }
  }
}
