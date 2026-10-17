$ErrorActionPreference = "Stop"
# update_roadmap_v3.ps1 - Roadmap Version 3: adds Study 2 (Steps 31A-31F, decision D28). Backs up Version 2 first.
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$path = Join-Path $root "00_Project_Admin\Project_Roadmap.docx"
$arch = Join-Path $root "00_Project_Admin\archive"; New-Item -ItemType Directory -Force $arch | Out-Null
$backup = Join-Path $arch "Project_Roadmap_v2_before_Study2_2026-10-12.docx"
if (-not (Test-Path $backup)) { Copy-Item $path $backup }
$prog = Join-Path $env:TEMP "dga_scratch\roadmap_v3_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$ENVCOL = 7949855

$steps = @(
  @{ n = "31A"; t = "Pre-register Study 2 (exploratory improvement study)"; i = "The confirmatory results of Steps 22-31; decisions_log.md."; d = "Write the Study 2 protocol before any Study 2 model is trained: questions, data rules, models A (released), B (pooled) and C (hybrid), measures, statistics, reject option and decision rules (decision D28). Record its SHA-256."; o = "00_Project_Admin/Study2_Protocol.docx; 03_Data/study2/study2_protocol.sha256."; c = "The protocol fingerprint is dated before the first Study 2 model; the confirmatory results stay unchanged." },
  @{ n = "31B"; t = "Build the pooled, deduplicated data set"; i = "dga_master.csv; conventional_predictions.csv; Study 2 protocol."; d = "Remove exact copies across sources by the fixed priority; form near-duplicate groups over all pooled records (Step 10 rule); merge T1 and T2; add the hybrid inputs (conventional answers, gate flags, boundary distances)."; o = "03_Data/study2/study2_pooled.csv with its SHA-256 manifest; table of records per source and class."; c = "No exact copy left across sources; every label conflict listed; data version 1.0 unchanged." },
  @{ n = "31C"; t = "Leave-one-source-out training and prediction"; i = "study2_pooled.csv; ml_config.yaml; dga_model_v1."; d = "Hold out each of the four sources in turn; train and tune models B and C on the other sources only (near-copies of held-out records removed from training); predict the held-out source once; apply model A unchanged."; o = "07_Experiments/<date>_study2_loso/ (configuration, seeds, predictions and probabilities)."; c = "No held-out record or near-copy in any training set; re-running a saved task gives identical predictions." },
  @{ n = "31D"; t = "Measures, paired contrasts and reject option"; i = "The Study 2 predictions; conventional answers of the same records."; d = "Macro-F1, strict and balanced accuracy with Wilson and bootstrap intervals; contrasts B-A, C-B and C against the best conventional method (bootstrap, McNemar with Holm); accuracy at the coverage of IEC 60599 and Rogers (Chow 1970)."; o = "Tables 4.12 (results by held-out source) and 4.13 (contrasts and reject option); Figures 4.23 (macro-F1 by held-out source and model) and 4.24 (accuracy against coverage)."; c = "Every number comes from the saved Study 2 predictions; all results labelled exploratory." },
  @{ n = "31E"; t = "Interpret Study 2 against its decision rules"; i = "Tables 4.12-4.13; the protocol."; d = "Apply the three pre-registered decision rules exactly as written and state what Study 2 shows and does not show, beside the confirmatory results."; o = "Study 2 report; 08_Statistical_Analysis/study2_decisions.json."; c = "Each decision follows the written rule; no confirmatory result is changed." },
  @{ n = "31F"; t = "Search for a fresh confirmation data set"; i = "Literature review; data cards."; d = "Search legitimate sources (journals, standards bodies, open repositories with a stated licence) for inspection-confirmed DGA cases not used so far; record each candidate, its licence and its overlap with the data already used. No data from pirated or unlicensed copies."; o = "03_Data/provenance/study2_confirmation_search.md."; c = "Every candidate has a citation and a licence statement; overlaps checked." }
)

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$d = $word.Documents.Open($path)
try {
  function Para([string]$start) { foreach ($i in 1..$d.Paragraphs.Count) { $p = $d.Paragraphs.Item($i); if ($p.Range.Text.Trim().StartsWith($start)) { return $p } }; throw "paragraph not found: $start" }
  # header and introduction
  $p = Para "Project Roadmap - Version 2"; $r = $p.Range; $r.MoveEnd(1, -1) | Out-Null; $f = $r.Find; [void]$f.Execute("Version 2", $false, $false, $false, $false, $false, $true, 0, $false, "Version 3", 1)
  $p = Para "Prepared: 9 October 2026"; $r = $p.Range; $r.MoveEnd(1, -1) | Out-Null; $r.InsertAfter("; Version 3, 12 October 2026: Study 2, an exploratory improvement study, added as Steps 31A to 31F (decision D28)")
  $p = Para "The whole project is carried out in three working environments"; $r = $p.Range; $r.MoveEnd(1, -1) | Out-Null; $r.InsertAfter(" Version 3 adds Study 2 (Steps 31A to 31F), done between Steps 31 and 32 after the confirmatory results; it has its own protocol, written before any Study 2 model was trained.")
  $p = Para "4. All 45 steps at a glance"; $r = $p.Range; $r.MoveEnd(1, -1) | Out-Null; $r.InsertAfter(" (plus Study 2, Steps 31A to 31F)")
  $p = Para "Stage F - Comparison and statistics (Steps 28 to 32)"; $r = $p.Range; $r.MoveEnd(1, -1) | Out-Null; $f = $r.Find; [void]$f.Execute("(Steps 28 to 32)", $false, $false, $false, $false, $false, $true, 0, $false, "(Steps 28 to 32, with Study 2 in Steps 31A to 31F)", 1)
  $p = Para "There are two formal gates."; $r = $p.Range; $r.MoveEnd(1, -1) | Out-Null; $r.InsertAfter(" Study 2 (Steps 31A to 31F) was added after the confirmatory results at the researcher's request; it is pre-registered in its own protocol and reported as exploratory.")
  $p = Para "Do: Run one script that rebuilds every Chapter 4 table and figure"; $r = $p.Range; $r.MoveEnd(1, -1) | Out-Null; $r.InsertAfter(" The Study 2 tables and figures (Tables 4.12-4.13, Figures 4.23-4.24) are rebuilt the same way, in their own section labelled exploratory.")

  # step paragraphs, inserted before Step 32
  $s32 = Para "Step 32  [CLAUDE CODE]"
  $fmt = @{ before = $s32.SpaceBefore; after = $s32.SpaceAfter }
  $sel = $word.Selection
  $sel.SetRange($s32.Range.Start, $s32.Range.Start)
  $sel.Font.Bold = 0; $sel.Font.Color = -16777216
  $sel.ParagraphFormat.LeftIndent = 0; $sel.ParagraphFormat.SpaceBefore = 10; $sel.ParagraphFormat.SpaceAfter = 3
  $sel.Font.Italic = 1
  $sel.TypeText("Study 2 - exploratory improvement study (Steps 31A to 31F, decision D28). Added in Version 3 after the confirmatory results; protocol: 00_Project_Admin/Study2_Protocol.docx. The confirmatory results of Steps 22-31 are not changed.")
  $sel.TypeParagraph(); $sel.Font.Italic = 0
  foreach ($s in $steps) {
    $sel.ParagraphFormat.LeftIndent = 0; $sel.ParagraphFormat.SpaceBefore = 10; $sel.ParagraphFormat.SpaceAfter = 3; $sel.ParagraphFormat.KeepWithNext = -1
    $sel.Font.Bold = 1; $sel.Font.Color = -16777216; $sel.TypeText("Step " + $s.n + "  ")
    $sel.Font.Color = $ENVCOL; $sel.TypeText("[CLAUDE CODE]")
    $sel.Font.Color = -16777216; $sel.TypeText("  " + $s.t); $sel.TypeParagraph()
    foreach ($kv in @(@("Input: ", $s.i), @("Do: ", $s.d), @("Output: ", $s.o), @("Check: ", $s.c))) {
      $sel.ParagraphFormat.LeftIndent = 21; $sel.ParagraphFormat.SpaceBefore = 0; $sel.ParagraphFormat.SpaceAfter = 2; $sel.ParagraphFormat.KeepWithNext = 0
      $sel.Font.Bold = 1; $sel.TypeText($kv[0]); $sel.Font.Bold = 0; $sel.TypeText($kv[1]); $sel.TypeParagraph()
    }
  }
  # restore the paragraph format of Step 32 (typing at its start applied the last format to it)
  $s32 = Para "Step 32  [CLAUDE CODE]"
  $s32.LeftIndent = 0; $s32.SpaceBefore = $fmt.before; $s32.SpaceAfter = $fmt.after; $s32.KeepWithNext = -1

  # overview table: rows before step 32
  $tbl = $null
  foreach ($ti in 1..$d.Tables.Count) { $t = $d.Tables.Item($ti); if ($t.Cell(1, 1).Range.Text -like "Step*" -and $t.Rows.Count -ge 46) { $tbl = $t } }
  if (-not $tbl) { throw "overview table not found" }
  $row32 = $null
  foreach ($ri in 2..$tbl.Rows.Count) { if (($tbl.Cell($ri, 1).Range.Text -replace "[\r\a]", "").Trim() -eq "32") { $row32 = $ri; break } }
  $outs = @{ "31A" = "Study2_Protocol.docx"; "31B" = "study2_pooled.csv"; "31C" = "07_Experiments study2_loso"; "31D" = "Tables 4.12-4.13; Figs 4.23-4.24"; "31E" = "Study 2 report"; "31F" = "study2_confirmation_search.md" }
  $k = 0
  foreach ($s in $steps) {
    $new = $tbl.Rows.Add($tbl.Rows.Item($row32 + $k))
    $vals = @($s.n, "Claude Code", ("Study 2: " + $s.t.Substring(0, 1).ToLower() + $s.t.Substring(1)), $outs[$s.n])
    foreach ($ci in 1..4) { $new.Cells.Item($ci).Range.Text = $vals[$ci - 1]; $new.Cells.Item($ci).Range.Font.Italic = 1 }
    $k++
  }
  $d.Save()
  ("SAVED roadmap v3 " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $d.Close($false); $word.Quit()
}
