$ErrorActionPreference = "Stop"
# build_step_report_31E.ps1 - Word report of roadmap Step 31E (Study 2 decision rules). Values from study2_decisions.json.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report31E_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$dec = Get-Content (Join-Path $root "08_Statistical_Analysis\study2\study2_decisions.json") -Raw | ConvertFrom-Json
$p = $dec.primary
if ($p.rule1_pooling_helps.met -or $p.rule2_hybrid_helps.met -or -not $p.rule3_reject_option_competitive.strict_reading_lower_limit_ge_0.met -or -not $p.rule3_reject_option_competitive.readings_agree) { throw "text assumes rule1 no, rule2 no, rule3 yes (both readings)" }
$SN = @{ DISTRAIN = "Dissanayake training"; DISTEST = "Dissanayake unseen"; IECTC10 = "IEC TC 10"; LI2019 = "Li 2019" }
function Per($o) { ($o.PSObject.Properties | ForEach-Object { $SN[$_.Name] + " " + $(if ($_.Value) { "yes" } else { "no" }) }) -join "; " }
function YN($b) { if ($b) { "MET" } else { "NOT MET" } }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
$global:Methods["31E"] = @{
  Approach = @(
    "The three decision rules written in the Study 2 protocol before any model was trained were applied, by a program, exactly as written to the results of Step 31D, for the primary analysis and for the two sensitivity variants.",
    "Rule 3 says the interval of the difference must be 'not below 0'. Because the results had already been seen when this wording was examined, the program applied both possible readings - lower limit at least 0 (strict) and estimate at least 0 (lenient) - and reports whether they agree.")
  Why = @("Applying rules fixed in advance, by program, is what turns an exploratory study into an honest one: the conclusion cannot be shaped after seeing the numbers.")
  Settings = @(
    @("Rule 1 (pooling)", "B - A macro-F1 > 0 with CI excluding 0 on at least 2 of 3 external sources"),
    @("Rule 2 (hybrid)", "C - B macro-F1 > 0 with CI excluding 0 on at least 2 of 4 held-out sources"),
    @("Rule 3 (reject option)", "model C at IEC 60599's coverage at least as accurate as IEC on at least 2 of 3 external sources; both readings applied"),
    @("Status", "EXPLORATORY"))
  Eqs = @()
  Tools = @("06_Python_ML/src/study2/step31e_decisions.py")
  Refs = @("M32")
}
$global:Closings["31E"] = @{
  Achieved = @("Study 2 is decided by its pre-registered rules: pooling and the hybrid model are not shown to help; the reject option is shown to make the model competitive with IEC 60599.", "The conclusion is the same under both readings of rule 3 and is reported beside, not instead of, the confirmatory results.")
  Record = @(
    @("Step", "31E - Interpret Study 2 against its decision rules"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done - EXPLORATORY"),
    @("Main inputs", "08_Statistical_Analysis/study2/contrasts.csv, reject_option.csv (Step 31D); Study 2 protocol"),
    @("Main outputs", "08_Statistical_Analysis/study2/study2_decisions.json"),
    @("Checks", "rules applied by program; both readings of rule 3 agree"),
    @("Decisions", "none new (D28, D29)"))
  Helps = @("Step 31F searches for a fresh, legitimately licensed set of inspection-confirmed cases on which the reject-option result could be confirmed.", "Chapter 4 reports Study 2 in its own exploratory section; Chapter 5 can recommend the reject option for practice.")
  Open = @(
    "Study 2 is exploratory: IEC TC 10 and Li 2019 had been seen before. The reject-option result needs confirmation on fresh data.",
    "Most estimated gains of pooling and of the hybrid model are positive on the external sources, but too small for these sample sizes to confirm; 'not shown' does not mean 'no effect'.",
    "In one sensitivity variant (all 117 IEC TC 10 records) rule 1 is met; in the primary analysis and the equal-weight variant it is not - the pooling result is therefore fragile.")
  Exclude = @()
}
$global:StepSources["31E"] = @("DF43", "DF40", "SW1")
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "31E" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "31E" "Interpret Study 2 against its decision rules" "Claude Code (this chat)"
Summary "By its own rules, fixed before any Study 2 model was trained: (1) training on several sources is not shown to help, (2) adding the conventional methods' answers is not shown to help, and (3) letting the model decline uncertain cases is shown to make it at least as accurate as IEC 60599 at the same answer rate. The practical lesson is that the ML model is most useful as a 'confident or refer' tool. These results are exploratory and do not change the confirmatory verdict."
H1N "Purpose of this step"
Body "This step states what Study 2 shows and does not show, using only the decision rules written in its protocol."
MethodSection "31E"
H1N "What was done"
NumItem "1" "Wrote step31e_decisions.py and applied the rules to the Step 31D results for all three variants."
NumItem "2" "For rule 3, applied both readings of 'not below 0' and checked that they agree."
H1N "Decisions of the rules"
$rows = @()
foreach ($v in "primary", "equal_source_weight", "iec_all") {
  $x = $dec.$v
  $vn = @{ primary = "Primary"; equal_source_weight = "Equal source weight"; iec_all = "IEC TC 10 all 117" }[$v]
  $rows += , @($vn, ("Rule 1: " + (YN $x.rule1_pooling_helps.met) + " (" + $x.rule1_pooling_helps.count + " of 3)"), ("Rule 2: " + (YN $x.rule2_hybrid_helps.met) + " (" + $x.rule2_hybrid_helps.count + " of 4)"), ("Rule 3: " + (YN $x.rule3_reject_option_competitive.strict_reading_lower_limit_ge_0.met) + " strict (" + $x.rule3_reject_option_competitive.strict_reading_lower_limit_ge_0.count + " of 3), " + (YN $x.rule3_reject_option_competitive.lenient_reading_point_ge_0.met) + " lenient (" + $x.rule3_reject_option_competitive.lenient_reading_point_ge_0.count + " of 3)"))
}
AddTable @("Analysis", "Pooling (B - A)", "Hybrid (C - B)", "Reject option (C vs IEC 60599)") $rows @(90, 110, 110, 150)
H2 "Per source (primary analysis)"
Bullet ("Rule 1 - interval of B - A excludes 0: " + (Per $p.rule1_pooling_helps.per_source) + ".")
Bullet ("Rule 2 - interval of C - B excludes 0: " + (Per $p.rule2_hybrid_helps.per_source) + ". The hybrid model is significantly WORSE when the Dissanayake training set is held out (" + ($p.note_hybrid_significantly_worse_on -join ", ") + "), where only 204 records remain for training.")
Bullet ("Rule 3 - strict reading: " + (Per $p.rule3_reject_option_competitive.strict_reading_lower_limit_ge_0.per_source) + "; lenient reading: " + (Per $p.rule3_reject_option_competitive.lenient_reading_point_ge_0.per_source) + ".")
H1N "What Study 2 shows and does not show"
Bullet "Shown (exploratory): a reject option is the most effective remedy. When the hybrid model answers only as many records as IEC 60599 does, keeping its most confident answers, it is more accurate than IEC 60599 on every source, clearly so on the Dissanayake and Li 2019 sources. For a utility this suggests a 'confident or refer' workflow: accept the model's diagnosis when it is confident, and send the rest to an engineer and to further tests."
Bullet "Not shown: that training on several sources, or giving the model the conventional answers, improves performance on a new source by more than the uncertainty. The estimated gains on the external sources are mostly positive (for example, on IEC TC 10 the macro-F1 rises from 0.731 for the released model to 0.821 for the hybrid model), but the intervals include zero, and the sensitivity variants disagree."
Bullet "Unchanged: the confirmatory verdict of Steps 22-31 (hypothesis not supported on the IEC TC 10 benchmark). Study 2 is reported separately and labelled exploratory."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Rules applied by program, exactly as written in the protocol", "PASS")
  , @("Both readings of rule 3 lead to the same conclusion", "PASS")
  , @("Confirmatory results untouched", "PASS")
) @(300, 150)
H1N "Problems and fixes"
Bullet "The first run of the decision program stopped because the equal-source-weight variant had no model A predictions; Step 31D was corrected (model A reused for the same records) and re-run with identical primary results, then the rules were applied."
H1N "Decisions"
Bullet "No new decision (D28, D29)."
H1N "Files produced"
Bullet "08_Statistical_Analysis/study2/study2_decisions.json; 06_Python_ML/src/study2/step31e_decisions.py; 03_Data/interim/step31e_report.md"
Closing "31E" 0 "Step 31F: search legitimate sources for a fresh set of inspection-confirmed DGA cases on which the reject-option result could be confirmed." $global:Blocks["31E"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $r2 = $doc.Content; $r2.SetRange($r2.End - 2, $r2.End - 1); if ($r2.Text -ne [string][char]13) { break }; $r2.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_31E_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_31E_Report.docx") -Force
("SAVED Step_31E_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " | " + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
