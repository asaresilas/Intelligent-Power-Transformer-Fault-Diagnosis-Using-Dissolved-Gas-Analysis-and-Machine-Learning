param([string]$raw, [string]$out)
# finish_thesis.ps1 - Word COM pass over the raw thesis written by build_thesis.py:
#  1. turns every paragraph of style "Equation" (UnicodeMath text ending in #(n.m)) into a numbered Word equation;
#  2. updates all fields (PAGEREF page numbers in the contents lists, PAGE in the footers);
#  3. saves. The raw file is first copied to a scratch folder and saved there with Save() at script level
#     (SaveAs2 inside a script block hangs on this machine - see memory note), then copied to $out.
$ErrorActionPreference = "Stop"
$scratch = Join-Path $env:TEMP "dga_scratch"
New-Item -ItemType Directory -Force $scratch | Out-Null
$work = Join-Path $scratch "thesis_work.docx"
Copy-Item $raw $work -Force
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $word.Documents.Open($work, $false, $false)
$doc.ActiveWindow.View.Type = 3
$paras = New-Object System.Collections.ArrayList
foreach ($p in $doc.Paragraphs) { if ($p.Style.NameLocal -eq "Equation") { [void]$paras.Add($p) } }
for ($i = $paras.Count - 1; $i -ge 0; $i--) {
  $p = $paras[$i]
  $r = $doc.Range($p.Range.Start, $p.Range.End - 1)
  $m = $doc.OMaths.Add($r)
  $m.OMaths.Item(1).BuildUp()
}
"equations built: " + $paras.Count + "  " + (Get-Date -Format HH:mm:ss)
$doc.Repaginate()
[void]$doc.Fields.Update()
$doc.Repaginate()
[void]$doc.Fields.Update()
"fields updated, pages: " + $doc.ComputeStatistics(2) + "  " + (Get-Date -Format HH:mm:ss)
$doc.Save()
"saved " + (Get-Date -Format HH:mm:ss)
$doc.Close(0)
$word.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
Copy-Item $work $out -Force
"copied to $out"
