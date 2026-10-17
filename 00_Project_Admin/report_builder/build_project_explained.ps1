$ErrorActionPreference = "Stop"
# build_project_explained.ps1 - Word document "The project explained simply" (17 Oct 2026), written for a reader with no technical background.
# Numbers come from the thesis facts (827 records, 388 held-out, accuracies of the test sets) and from 10_Dashboard_Client/results/dashboard_verdict_summary.csv.
# Body 12 pt, line spacing 1.15 (project rule). ASCII only. No PDF export (Word COM PDF export hangs on this machine).
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$out  = Join-Path $root "00_Project_Admin\Project_Explained_Simply.docx"
$fig1 = Join-Path $root "00_Project_Admin\layman_figures\L1_big_picture.png"
$fig2 = Join-Path $root "00_Project_Admin\layman_figures\L2_three_parts.png"
$shotFault = Join-Path $root "10_Dashboard_Client\results\step44_screen2_fault.png"
$shotHealthy = Join-Path $root "10_Dashboard_Client\results\step44_screen1_healthy.png"
$sum = Import-Csv (Join-Path $root "10_Dashboard_Client\results\dashboard_verdict_summary.csv")
function SumVal($name) { [int](($sum | Where-Object { $_.item -eq $name }).value) }
$nKnownFault = SumVal "known faulty"; $nFaultCalled = SumVal "faulty records called fault"; $nFaultHealthy = SumVal "faulty records called healthy"
$nNormal = SumVal "known Normal"; $nNormalHealthy = SumVal "Normal records called healthy"
$nVerdictFault = SumVal "fault verdict with known class"; $nRight = SumVal "fault verdict with the right class"; $nFam = SumVal "fault verdict, family right"

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $word.Documents.Add()
$sel = $word.Selection
$doc.PageSetup.PaperSize = 7   # A4
$doc.PageSetup.LeftMargin = 72; $doc.PageSetup.RightMargin = 72; $doc.PageSetup.TopMargin = 72; $doc.PageSetup.BottomMargin = 72
$n = $doc.Styles.Item(-1)      # Normal
$n.Font.Name = "Calibri"; $n.Font.Size = 12
$n.ParagraphFormat.SpaceAfter = 6; $n.ParagraphFormat.LineSpacingRule = 5; $n.ParagraphFormat.LineSpacing = 12 * 1.15 * 1.0
$n.ParagraphFormat.LineSpacingRule = 5; $n.ParagraphFormat.LineSpacing = 13.8   # multiple 1.15 = 13.8 pt "multiple"
foreach ($i in 1..3) { $h = $doc.Styles.Item(-1 - $i); $h.Font.Name = "Calibri"; $h.Font.Color = 0x5A3A1F; $h.Font.Bold = $true }
$doc.Styles.Item(-2).Font.Size = 18; $doc.Styles.Item(-3).Font.Size = 14; $doc.Styles.Item(-4).Font.Size = 12

function Para([string]$t, [string]$style = "Normal", [bool]$bold = $false, [bool]$italic = $false) {
  $sel.Style = $doc.Styles.Item($style)
  $sel.Font.Bold = [int]$bold; $sel.Font.Italic = [int]$italic
  $sel.TypeText($t); $sel.TypeParagraph()
  $sel.Font.Bold = 0; $sel.Font.Italic = 0
}
function H1([string]$t) { Para $t "Heading 1" }
function H2([string]$t) { Para $t "Heading 2" }
function P([string]$t) { Para $t }
function Bul([string[]]$items) {
  foreach ($t in $items) { $sel.Style = $doc.Styles.Item("List Bullet"); $sel.TypeText($t); $sel.TypeParagraph() }
  $sel.Style = $doc.Styles.Item("Normal")
}
function Fig([string]$path, [string]$cap, [double]$wcm = 15.5) {
  if (-not (Test-Path $path)) { return }
  $sel.Style = $doc.Styles.Item("Normal"); $sel.ParagraphFormat.Alignment = 1
  $pic = $sel.InlineShapes.AddPicture($path, $false, $true)
  $r = $pic.Height / $pic.Width; $pic.Width = $wcm * 28.35; $pic.Height = $pic.Width * $r
  $sel.TypeParagraph()
  $sel.Font.Italic = 1; $sel.TypeText($cap); $sel.Font.Italic = 0; $sel.TypeParagraph()
  $sel.ParagraphFormat.Alignment = 0
}
function Tbl($rows, [double[]]$widths) {
  $nr = $rows.Count; $nc = $rows[0].Count
  $sel.Style = $doc.Styles.Item("Normal")
  $t = $doc.Tables.Add($sel.Range, $nr, $nc)
  $t.Borders.Enable = $true
  for ($r = 0; $r -lt $nr; $r++) { for ($c = 0; $c -lt $nc; $c++) {
    $cell = $t.Cell($r + 1, $c + 1); $cell.Range.Text = $rows[$r][$c]; $cell.Range.Font.Size = 11
    $cell.Range.ParagraphFormat.SpaceAfter = 2
    if ($r -eq 0) { $cell.Range.Font.Bold = 1; $cell.Shading.BackgroundPatternColor = 0xEFE3D5 } } }
  if ($widths) { for ($c = 0; $c -lt $nc; $c++) { $t.Columns.Item($c + 1).PreferredWidthType = 3; $t.Columns.Item($c + 1).PreferredWidth = $widths[$c] * 28.35 } }
  $sel.EndKey(6) | Out-Null
  $sel.TypeParagraph()
}

# ------------------------------------------------------------------------------------------------------------------------
$sel.Style = $doc.Styles.Item("Title")
$sel.TypeText("The project explained simply"); $sel.TypeParagraph()
Para "Finding faults inside a power transformer from the gases in its oil, with a computer that learns" "Subtitle"
P "This document explains the whole project in everyday words. You do not need to know anything about electricity, chemistry or computing. Every number in it comes from the project's own results. Words in CAPITALS are explained in the list at the end."

H1 "1  The problem in one minute"
P "A power transformer is a large machine that changes electricity from one voltage to another, so that power can travel far from the power station and then be made safe for homes and factories. One transformer can weigh hundreds of tonnes and cost millions. If it fails suddenly, whole towns can lose power and the repair can take many months."
P "Inside the transformer the metal coils are soaked in special oil. The oil keeps the coils cool and stops sparks. When something starts to go wrong inside, for example an overheated spot or a small electrical spark, the oil and the paper around the coils break down a little, and they release gases that dissolve in the oil. Different faults release different mixtures of gases."
P "Think of it like a blood test at the doctor. The oil is the transformer's blood. A small sample of oil is taken, a laboratory measures the gases in it, and an engineer reads the result to find out whether the transformer is healthy, and if not, what kind of illness it has. This reading is called DGA, short for Dissolved Gas Analysis. It is the standard early-warning method used all over the world."

H1 "2  Why this project was needed"
P "For about fifty years engineers have used rulebooks to read the gas numbers. This project looks at three of them: the Rogers ratio method, the IEC 60599 ratio method and the Duval Triangle. Each rulebook turns the gas numbers into one of a short list of answers. The trouble is that the rulebooks often disagree with each other, and sometimes a rulebook gives no answer at all."
P "A newer idea is to let a computer learn from many past cases where the true answer is known. This is called MACHINE LEARNING. The research question of this project is simple: is the computer better than the rulebooks, and can both be put on one screen so that an engineer can compare them?"

H1 "3  The five gases and the seven possible answers"
P "Five gases are measured. They are written with chemical symbols: hydrogen (H2), methane (CH4), ethane (C2H6), ethylene (C2H4) and acetylene (C2H2). The amount of each is given in ppm, which means parts per million."
P "The answer is one of seven labels, taken from the international standard IEC 60599:"
Tbl @(
 @("Label", "What it means in plain words", "Gases that give it away"),
 @("Normal", "No fault. The transformer is healthy.", "All gases low"),
 @("PD", "Partial discharges: tiny electrical sparks inside the insulation.", "Mostly hydrogen"),
 @("D1", "Low-energy discharges: weak electrical sparks.", "Hydrogen and acetylene"),
 @("D2", "High-energy discharges: strong electrical arcing. Serious.", "Acetylene, hydrogen, ethylene"),
 @("T1", "Mild overheating, below 300 degrees Celsius.", "Methane and ethane"),
 @("T2", "Medium overheating, 300 to 700 degrees Celsius.", "Ethylene and methane"),
 @("T3", "Severe overheating, above 700 degrees Celsius. Serious.", "Mostly ethylene")
) @(2.2, 8.3, 5.0)
P "The first three are electrical faults (sparks). The last three are thermal faults (heat). Normal means that nothing is wrong."

H1 "4  The three rulebooks"
P "A rulebook does not look at the gas amounts alone. It divides one gas by another, for example methane divided by hydrogen. These divisions are called RATIOS. Each fault produces a typical combination of ratios, like a fingerprint. The rulebook compares the fingerprint of the sample with a table of known fingerprints."
Bul @(
 "Rogers ratio method (from the standard IEEE C57.104, USA). Uses three ratios and a table of numbered cases.",
 "IEC 60599 ratio method (international standard). Uses the same three ratios with a different table. It can answer D1/D2 when it cannot tell weak sparks from strong ones.",
 "Duval Triangle 1 (by Michel Duval, used inside IEC 60599). Uses three gases, turns them into percentages and marks a point in a triangle that is divided into coloured zones. The zone is the answer. It can answer DT, which means a mixture of heat and sparks."
)
P "Before any rulebook is used, a first check is applied, exactly as the standard describes: every gas is compared with a typical value, which is the level that about nine out of ten healthy transformers stay below. If all five gases are at or below their typical values, the transformer is called healthy and no fault type is looked for. If at least one gas is above, the rulebooks are used to find the fault type."
P "A rulebook can also say ND, which means no diagnosis: the numbers fit none of its fingerprints."

H1 "5  The computer model"
P "The computer model is a RANDOM FOREST. Picture a large committee of simple decision trees. Each tree asks a few yes/no questions about the gases, for example is the hydrogen very high, and votes for one of the seven labels. The label with the most votes wins, and the share of votes is the probability the dashboard shows."
P "The model was taught with 439 labelled records, so it learned from cases where the real fault was known. The whole collection has 827 records of five gases, taken from published studies and checked for duplicates and mistakes. The remaining 388 records were kept locked away and used only to test the model on cases it had never seen. This is like giving a student an exam with new questions."

H1 "6  The three parts of the project"
Fig $fig2 "Figure 1. The three parts of the project and how they talk to each other." 15.5
Bul @(
 "PYTHON is the learner. It builds the model and, in addition, offers it as a small service on the same computer, like a waiter who takes a gas record and brings back an answer.",
 "SIMULINK and MATLAB are the operator. Simulink contains a physics model of a 40 MVA transformer. It calculates how hot the oil and the winding become when the transformer carries a heavier or lighter load during the day, and how fast the paper insulation is ageing. It also takes oil samples at set times. IMPORTANT: Simulink never makes up gas numbers. The gas numbers always come from the real measured records. The simulation only describes how hard the transformer is working. MATLAB also computes the three rulebooks.",
 "The DASHBOARD is the screen. It starts the service itself, runs the simulation, takes the samples, asks the three rulebooks and the computer model, and shows everything side by side."
)

H1 "7  How to read the dashboard, step by step"
Fig $fig1 "Figure 2. From a drop of oil to a decision." 15.5
P "The dashboard follows the same order as the international procedure (IEC 60599 and IEEE C57.104):"
Tbl @(
 @("Step", "What happens", "Where you see it"),
 @("1", "The sample: five gas numbers from a measured record.", "Table on the left, tab 'Step by step'"),
 @("2", "Check against the typical values. All low means HEALTHY.", "Chart 'Gas level', first lines of 'Step by step'"),
 @("3", "If a gas is high: compute the gas ratios.", "Tab 'Step by step'"),
 @("4 to 6", "Read the three rulebooks: IEC 60599, Rogers, Duval Triangle.", "Three of the five cards, and the Duval Triangle chart"),
 @("7", "Ask the machine-learning model.", "Fourth card and the probability chart"),
 @("8", "Compare. Each method gives one vote. The answer with the most votes (at least two) is the verdict.", "The coloured banner at the top")
) @(1.8, 8.7, 5.0)
P "The coloured banner is the answer:"
Bul @(
 "GREEN: HEALTHY. All five gases are within the typical values. No action is needed.",
 "RED: FAULT. At least one gas is high and the methods name a fault type. The banner says which type, how many of the methods agree, and what to do (for example take a repeat sample and compare it with earlier ones).",
 "AMBER: WATCH or CHECK. Either the gases are high but the methods see no clear fault, or the methods cannot agree. Do not decide on one method. Take a repeat sample and look at the trend."
)
P "Below the banner there are five cards. The first four show the answer of Rogers, IEC 60599, Duval and the computer model, with a plain meaning and one word: AGREES (it gave the same answer as the verdict), DIFFERS, or NO ANSWER (the method gave ND or DT). The fifth card shows the known true label of the record when the data file contains it, so that you can see who was right."
P "On the left you choose how the demonstration is run:"
Bul @(
 "Operating condition: constant rated load, a daily load cycle, or a short overload. This changes only the temperatures of the simulated transformer.",
 "Oil samples: a MIXED set (one healthy sample and one of each of the six fault types, so that you see every state), RANDOM records, or the first four records (the test run).",
 "Or look at one record: choose a fault type, press 'Pick random record', or type a record number."
)
Fig $shotFault "Figure 3. The dashboard showing a fault: banner, four method cards and charts." 16
Fig $shotHealthy "Figure 4. The dashboard showing a healthy sample." 16

H1 "8  What the study found"
P ("The results below come from the test records that the model never saw during teaching. 'Strict accuracy' means the method must name exactly the right label.")
Bul @(
 "On the internal test set (61 records) the computer model was right 82.0 % of the time. The rulebooks were right 32.8 % (Rogers), 47.5 % (IEC 60599) and 55.7 % (Duval Triangle). The model was clearly better.",
 "On the most trusted test set (58 records of the IEC TC 10 collection, where faults were confirmed by opening the transformer) the model was right 72.4 %, Rogers 48.3 %, IEC 60599 63.8 % and Duval Triangle 77.6 %. The model was better than Rogers, but not significantly different from IEC 60599 or the Duval Triangle. So the claim that the computer beats the rulebooks was NOT proven on the most trusted test.",
 "The rulebooks and the model often disagree. Putting them side by side, and giving a verdict by vote, is what the dashboard is for.",
 "A simple physics model of the transformer reproduced the temperatures within 0.1 degree Celsius of the reference calculation, and the dashboard reproduced the offline answers for all 388 test records, with an answer time of about 95 milliseconds in 95 cases out of 100.",
 "The honest conclusion is that machine learning is a useful second opinion, not a replacement for the standard rulebooks."
)
P ("A check made for the new verdict (17 October 2026) on the 388 test records, using the known labels: of " + $nKnownFault + " records with a known fault, the verdict said FAULT for " + $nFaultCalled + " and HEALTHY for " + $nFaultHealthy + ". These " + $nFaultHealthy + " are faults with very low gas levels that the standard's first check passes as normal. This is a known limit of the typical-value check: the typical values are not fault limits. Of " + $nNormal + " known healthy records, " + $nNormalHealthy + " were called HEALTHY. When the verdict was FAULT and the true class was known (" + $nVerdictFault + " records), the exact type was right for " + $nRight + " and the right family (electrical or thermal) for " + $nFam + ". These figures are descriptive and are not a new statistical test.")

H1 "9  What the project does not do"
Bul @(
 "It does not replace an engineer or an inspection. The dashboard is decision support.",
 "It does not use real utility data from Ghana yet. All 827 records come from published studies. Real data from a utility, through the supervisor, is a possible next step.",
 "It does not predict how long a transformer will last.",
 "The simulation does not produce gases. The temperatures give context only."
)

H1 "10  Words explained"
Tbl @(
 @("Word", "Meaning"),
 @("Transformer", "A machine that changes the voltage of electricity."),
 @("DGA", "Dissolved Gas Analysis: measuring the gases dissolved in the transformer oil."),
 @("ppm", "Parts per million: a very small amount, 1 ppm is one millilitre in 1000 litres."),
 @("Ratio", "One gas amount divided by another."),
 @("Typical value", "The gas level that about 90 % of healthy transformers stay below (IEC 60599, Annex A). It is not a fault limit."),
 @("Partial discharge / arcing", "Small / strong electrical sparks inside the insulation."),
 @("Machine learning", "A computer program that learns patterns from past cases instead of being given rules."),
 @("Random forest", "A machine-learning method made of many decision trees that vote."),
 @("Simulink / MATLAB", "Engineering software used for the physics model and the dashboard."),
 @("Service (FastAPI)", "A small program that waits for a request and sends back an answer."),
 @("Held-out records", "Records that the model never saw while it was learning: the exam questions."),
 @("Verdict", "The one answer of the dashboard, made from the votes of the four methods.")
) @(4.0, 11.5)

$doc.Fields.Update() | Out-Null
$doc.SaveAs2([string]$out, 16)
$doc.Close()
$word.Quit()
"written " + $out
