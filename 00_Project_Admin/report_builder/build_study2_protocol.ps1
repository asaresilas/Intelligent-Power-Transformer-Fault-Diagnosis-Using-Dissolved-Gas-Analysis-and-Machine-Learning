$ErrorActionPreference = "Stop"
# build_study2_protocol.ps1 - Study 2 protocol (pre-registration, decision D28). Written BEFORE any Study 2 model is trained.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$prog = Join-Path $work "protocol_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
$global:sec = 0; $global:eqn = 0
Title "Study 2 Protocol" 18
Title "Exploratory improvement study: training on several sources, a hybrid model and a reject option" 13
Center "Pre-registered on 12 October 2026, before any Study 2 model was trained   |   Version 1   |   Decision D28"
Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
Summary "The main (confirmatory) results of Steps 22-31 stay exactly as they are: the research hypothesis was not supported on the IEC TC 10 benchmark. Study 2 asks, as a separate and clearly labelled exploratory study, whether the model can be improved by (1) training on several data sources, (2) giving it the conventional methods' answers as extra inputs, and (3) letting it decline to answer when unsure. Every choice is fixed in this document before any Study 2 model is trained. Because the IEC TC 10 and Li 2019 sets have already been seen, a positive Study 2 result can only motivate, not prove, an improvement; proof needs a fresh data set (Step 31F)."

H1N "Why Study 2 is needed and what it may claim"
Body "The confirmatory study showed a fall in accuracy from the internal test set (0.82) to the IEC TC 10 benchmark (0.72) and Li 2019 (0.63). The most likely cause is dataset shift: the model was trained on one source whose labelling method is not documented (decision D7). Study 2 tests three standard remedies."
Bullet "What Study 2 may claim: whether each remedy improves performance on a data source the model did not see during training, measured by leave-one-source-out evaluation."
Bullet "What it may not claim: a confirmed improvement on IEC TC 10 or Li 2019, because these sets were used in Steps 22-31 and influenced the decision to run Study 2. Results on them are exploratory. The confirmatory results are never replaced or re-labelled."

H1N "Questions"
NumItem "S2-Q1" "Does training on several sources (model B) predict an unseen source better than training on the Dissanayake training set alone (model A)?"
NumItem "S2-Q2" "Does adding the conventional methods' answers and boundary distances as inputs (hybrid model C) improve on model B?"
NumItem "S2-Q3" "If the model may decline to answer when its top probability is low (reject option), is it more accurate than each conventional method at the same coverage?"
NumItem "S2-Q4" "Is a fresh, legitimately licensed set of inspection-confirmed DGA cases available for confirmation?"

H1N "Data"
H2 "Sources and scope"
AddTable @("Source (held-out unit)", "Records used", "Notes") @(
  , @("Dissanayake training file (DISTRAIN)", "439 development records", "labels of undocumented origin (D7)")
  , @("Dissanayake unseen file (DISTEST)", "records independent of IEC TC 10", "the 9 IEC TC 10 copies belong to IEC TC 10")
  , @("IEC TC 10 (IECTC10)", "power transformers (codes P, U) - primary; all 117 records - sensitivity", "inspection-confirmed labels (approved item 8)")
  , @("Li 2019 (LI2019)", "records independent of IEC TC 10 and of DISTEST", "label mapping of approved item 7")
) @(150, 150, 160)
H2 "Deduplication and near-duplicates (fixed rules)"
Bullet "Exact copies across sources (identical five gas values) are kept once, in this order of priority: IEC TC 10 (inspection-confirmed), Dissanayake training, Dissanayake unseen, Li 2019. Where copies carry different labels, the IEC TC 10 label is kept and the conflict is listed."
Bullet "Near-duplicate groups are formed over ALL pooled records with the Step 10 rule (every gas within 1 % or 1 ppm, linked transitively). In every leave-one-source-out split, any training record that shares a group with a held-out record is removed from training, so no near-copy of a test record is ever learned."
Bullet "Classes: six - Normal, PD, D1, D2, T1/T2 merged, T3 - because IEC TC 10 has no separate T1 and T2 labels. A gas not detected is 0 ppm (decision D8). The exact numbers of records after these rules are produced and reported in Step 31B."
Bullet "The frozen data version 1.0 is not changed; Study 2 writes its own pooled file with its own SHA-256 manifest."

H1N "Design"
H2 "Leave-one-source-out evaluation"
Body "Each of the four sources is held out in turn. Models are trained and tuned on the other three sources only and then predict the held-out source once."
Eq 'S_test∈{"DISTRAIN","DISTEST","IECTC10","LI2019"}{SP}D_train=⋃_(S≠S_test)▒S∖G(S_test)'
WhereList @(@('S_test', 'the held-out source'), @('D_train', 'training records: all other sources'), @('G(S_test)', 'records that share a near-duplicate group with a held-out record (removed from training)'))
H2 "Models (all fixed now)"
AddTable @("Model", "Inputs", "Training") @(
  , @("A - released model", "F4 (18 gas features)", "dga_model_v1 unchanged (trained on DISTRAIN, Step 22); output T1 and T2 merged. Not applicable when DISTRAIN is held out.")
  , @("B - pooled", "F4 (18 gas features)", "Random Forest, 500 trees, balanced class weights, the same 9-point grid as Step 20; tuned by GridSearchCV with StratifiedGroupKFold(5) on the training sources (groups = pooled near-duplicate groups); macro-F1")
  , @("C - hybrid", "F4 + conventional inputs: raw answer of IEC 60599, Rogers and Duval (one-hot, including ND, DT and D1/D2); upper and lower gate flags; the three boundary distances (infinite or undefined -> training median plus a missing-value flag)", "as B")
  , @("Conventional methods", "five gases", "fixed rules of Steps 14-17; primary scoring of D25 (upper gate), merged classes")
) @(90, 170, 200)
Bullet "Seed: 20261012 (+ index of the held-out source). Everything that learns from data (imputer, scaler, class weights, tuning) is fitted on the training sources only. Sensitivity: equal total weight for each training source."
Bullet "The conventional inputs of model C are computed from each record's own gases with the fixed standard tables, so they contain no information from labels."

H1N "Measures and statistics"
Bullet "Primary measure: macro-F1 over the classes present in the held-out source. Secondary: strict accuracy, balanced accuracy, per-class F1."
Bullet "Intervals: Wilson for accuracy; stratified percentile bootstrap (B = 2000, records resampled within class, paired across models) for macro-F1 and for differences between models."
Bullet "Paired contrasts on each held-out source: B - A, C - B, and C against the conventional method with the highest strict accuracy on that source; McNemar (exact if b + c < 25) with Holm over the contrasts of that source."
H2 "Reject option (S2-Q3)"
Body "The model gives an answer only when its largest class probability reaches a threshold; otherwise it gives no diagnosis (Chow, 1970)."
Eq '"Coverage"(τ)=1/N ∑_(i=1)^N▒1[max_k p_ik≥τ]{SP}A_sel (τ)=(∑_i▒1[max_k p_ik≥τ]⋅1[y{HAT}_i=y_i ])/(∑_i▒1[max_k p_ik≥τ])'
WhereList @(@('τ', 'confidence threshold'), @('p_ik', 'predicted probability of class k for record i'), @('A_sel (τ)', 'accuracy on the records that receive an answer'))
Bullet "For each held-out source, τ is set so that the model's coverage equals the coverage of IEC 60599 (and, separately, of Rogers) on that source. Setting τ uses only the model's probabilities - never the true labels. The selective accuracy is then compared with the method's conditional accuracy (bootstrap CI of the difference). The full accuracy-coverage curve is also reported."

H1N "Decision rules (fixed before the results)"
NumItem "1" "Pooling helps (S2-Q1) if B - A > 0 in macro-F1 with a 95 % bootstrap interval excluding 0 on at least 2 of the 3 external sources (DISTEST, IECTC10, LI2019)."
NumItem "2" "The hybrid helps (S2-Q2) if C - B > 0 in macro-F1 with a 95 % interval excluding 0 on at least 2 of the 4 held-out sources."
NumItem "3" "The reject option makes the model competitive (S2-Q3) if, at the coverage of IEC 60599, its selective accuracy is at least that method's conditional accuracy (interval of the difference not below 0) on at least 2 of the 3 external sources."
NumItem "4" "Whatever the outcome, results are reported in full and as found, labelled exploratory, beside - never instead of - the confirmatory results."

H1N "Outputs and roadmap"
AddTable @("Roadmap step", "Content", "Main output") @(
  , @("31A", "This protocol (pre-registration)", "00_Project_Admin/Study2_Protocol.docx; decision D28")
  , @("31B", "Build the pooled, deduplicated data set with groups and hybrid inputs", "03_Data/study2/study2_pooled.csv + SHA-256 manifest")
  , @("31C", "Leave-one-source-out training and prediction (models A, B, C)", "07_Experiments/<date>_study2_loso/")
  , @("31D", "Measures, paired contrasts and reject option", "Tables 4.12-4.13; Figures 4.23-4.24")
  , @("31E", "Interpretation against the decision rules", "Study 2 report")
  , @("31F", "Search for a fresh confirmation data set (legitimate sources only)", "03_Data/provenance/study2_confirmation_search.md")
) @(60, 230, 170)
H1N "References"
Ref "C. Chow, ""On optimum recognition error and reject tradeoff,"" IEEE Transactions on Information Theory, vol. 16, no. 1, pp. 41-46, 1970. doi: 10.1109/TIT.1970.1054406"
Ref "B. Efron and R. J. Tibshirani, An Introduction to the Bootstrap. New York: Chapman and Hall, 1993."
Ref "Q. McNemar, ""Note on the sampling error of the difference between correlated proportions or percentages,"" Psychometrika, vol. 12, no. 2, pp. 153-157, 1947. doi: 10.1007/BF02295996"
Ref "S. Holm, ""A simple sequentially rejective multiple test procedure,"" Scandinavian Journal of Statistics, vol. 6, no. 2, pp. 65-70, 1979."
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Study2_Protocol.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $root "00_Project_Admin\Study2_Protocol.docx") -Force
("SAVED Study2_Protocol.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
