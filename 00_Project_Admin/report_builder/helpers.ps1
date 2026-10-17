# helpers.ps1 - shared Word COM helpers (dot-source after creating $word, $doc, $sel)
# Environment colours (Word colour = R + G*256 + B*65536)
$global:C_CC = 7949855    # dark blue   - Claude Code
$global:C_MT = 1137349    # dark orange - MATLAB Agentic Toolkit
$global:C_ST = 1930808    # dark green  - Simulink Agentic Toolkit
$global:C_AP = 10498160   # purple      - approval gate
$global:S_CC = 16247773   # light tints for table cells
$global:S_MT = 14083324
$global:S_ST = 14348258
$global:S_AP = 16048362
$global:eqn = 0
$global:lastTbl = $null

function Init-Doc {
  $n = $doc.Styles.Item("Normal")
  $n.Font.Name = "Times New Roman"
  $n.Font.Size = 12
  $n.ParagraphFormat.LineSpacingRule = 5      # wdLineSpaceMultiple
  $n.ParagraphFormat.LineSpacing = 13.8       # 1.15 x 12 pt
  $n.ParagraphFormat.SpaceAfter = 6
  $n.ParagraphFormat.SpaceBefore = 0
  foreach ($h in @(@("Heading 1", 15), @("Heading 2", 13), @("Heading 3", 12))) {
    $s = $doc.Styles.Item($h[0])
    $s.Font.Name = "Times New Roman"
    $s.Font.Size = $h[1]
    $s.Font.Bold = 1
    $s.ParagraphFormat.SpaceBefore = 12
    $s.ParagraphFormat.SpaceAfter = 6
  }
  $ps = $doc.PageSetup
  $ps.TopMargin = 72; $ps.BottomMargin = 72; $ps.LeftMargin = 72; $ps.RightMargin = 72
  $doc.Sections.Item(1).Footers.Item(1).PageNumbers.Add(1, $true) | Out-Null
}

function Reset-Para {
  $sel.ParagraphFormat.LeftIndent = 0
  $sel.ParagraphFormat.FirstLineIndent = 0
  $sel.ParagraphFormat.Alignment = 0
  $sel.ParagraphFormat.SpaceAfter = 6
  $sel.ParagraphFormat.SpaceBefore = 0
  $sel.ParagraphFormat.KeepWithNext = 0
  $sel.Font.Bold = 0
  $sel.Font.Italic = 0
  $sel.Font.Color = -16777216                 # automatic
  $sel.Font.Size = 12
}

function Set-Normal { $sel.Style = $doc.Styles.Item("Normal"); Reset-Para }

function Title([string]$t, [double]$size, [int]$bold = 1) {
  Set-Normal
  $sel.ParagraphFormat.Alignment = 1
  $sel.Font.Bold = $bold
  $sel.Font.Size = $size
  $sel.TypeText($t)
  $sel.TypeParagraph()
  Reset-Para
}

function Center([string]$t) { Set-Normal; $sel.ParagraphFormat.Alignment = 1; $sel.TypeText($t); $sel.TypeParagraph(); Reset-Para }

function H1([string]$t) { $sel.Style = $doc.Styles.Item("Heading 1"); $sel.TypeText($t); $sel.TypeParagraph(); Set-Normal }
function H1N([string]$t) { $global:sec++; H1 ("" + $global:sec + ". " + $t) }
function H2([string]$t) { $sel.Style = $doc.Styles.Item("Heading 2"); $sel.TypeText($t); $sel.TypeParagraph(); Set-Normal }
function H3([string]$t) { $sel.Style = $doc.Styles.Item("Heading 3"); $sel.TypeText($t); $sel.TypeParagraph(); Set-Normal }

function Body([string]$t) { Set-Normal; $sel.TypeText($t); $sel.TypeParagraph() }

function Ital([string]$t) { Set-Normal; $sel.Font.Italic = 1; $sel.TypeText($t); $sel.TypeParagraph(); Reset-Para }

function Caption([string]$t) {
  Set-Normal
  $sel.ParagraphFormat.KeepWithNext = -1
  $sel.ParagraphFormat.SpaceBefore = 6
  $sel.Font.Bold = 1
  $sel.Font.Size = 11
  $sel.TypeText($t)
  $sel.TypeParagraph()
  Reset-Para
}

function Bullet([string]$t) {
  Set-Normal
  $sel.ParagraphFormat.LeftIndent = 21
  $sel.ParagraphFormat.FirstLineIndent = -14
  $sel.TypeText([string][char]0x2022 + "  " + $t)
  $sel.TypeParagraph()
  Reset-Para
}

function NumItem([string]$n, [string]$t) {
  Set-Normal
  $sel.ParagraphFormat.LeftIndent = 21
  $sel.ParagraphFormat.FirstLineIndent = -14
  $sel.TypeText("$n.  $t")
  $sel.TypeParagraph()
  Reset-Para
}

function Ref([string]$t) {
  Set-Normal
  $sel.ParagraphFormat.LeftIndent = 21
  $sel.ParagraphFormat.FirstLineIndent = -21
  $sel.TypeText($t)
  $sel.TypeParagraph()
  Reset-Para
}

# Label line: bold label then text, indented (used inside step blocks)
function Label([string]$label, [string]$t, [switch]$Ital) {
  Set-Normal
  $sel.ParagraphFormat.LeftIndent = 21
  $sel.ParagraphFormat.SpaceAfter = 2
  $sel.Font.Bold = 1
  $sel.TypeText($label + " ")
  $sel.Font.Bold = 0
  if ($Ital) { $sel.Font.Italic = 1 }
  $sel.TypeText($t)
  $sel.TypeParagraph()
  Reset-Para
}

function EnvInfo([string]$env) {
  switch ($env) {
    "CC" { return @("CLAUDE CODE", $global:C_CC) }
    "MT" { return @("MATLAB AGENTIC TOOLKIT", $global:C_MT) }
    "ST" { return @("SIMULINK AGENTIC TOOLKIT", $global:C_ST) }
    "AP" { return @("APPROVAL GATE", $global:C_AP) }
  }
}

# Step heading: "Step 05  [CLAUDE CODE]  Title"
function StepHead([int]$num, [string]$env, [string]$title) {
  $info = EnvInfo $env
  Set-Normal
  $sel.ParagraphFormat.SpaceBefore = 10
  $sel.ParagraphFormat.SpaceAfter = 3
  $sel.ParagraphFormat.KeepWithNext = -1
  $sel.Font.Bold = 1
  $sel.TypeText(("Step {0:D2}  " -f $num))
  $sel.Font.Color = $info[1]
  $sel.TypeText("[" + $info[0] + "]")
  $sel.Font.Color = -16777216
  $sel.TypeText("  " + $title)
  $sel.TypeParagraph()
  Reset-Para
}

# Legend line with a coloured tag and a description
function Legend([string]$env, [string]$t) {
  $info = EnvInfo $env
  Set-Normal
  $sel.ParagraphFormat.LeftIndent = 21
  $sel.ParagraphFormat.SpaceAfter = 3
  $sel.Font.Bold = 1
  $sel.Font.Color = $info[1]
  $sel.TypeText("[" + $info[0] + "]")
  $sel.Font.Color = -16777216
  $sel.Font.Bold = 0
  $sel.TypeText("  " + $t)
  $sel.TypeParagraph()
  Reset-Para
}

# Placeholders: {SP}=two em spaces, {HAT}/{TILDE}/{BAR}=combining accents, {FA}=function application.
function Expand-Ph([string]$s) {
  $s = $s.Replace('{SP}', [string][char]0x2003 + [char]0x2003)
  $s = $s.Replace('{HAT}', [string][char]0x0302).Replace('{TILDE}', [string][char]0x0303).Replace('{BAR}', [string][char]0x0304)
  $s = $s.Replace('{FA}', [string][char]0x2061)
  return $s
}

# Paragraph with inline math: text with math written between ⟦ and ⟧ (UnicodeMath).
function BodyM([string]$t, [double]$indent = 0, [double]$hang = 0, [double]$after = 6, [switch]$Keep) {
  Set-Normal
  $sel.ParagraphFormat.LeftIndent = $indent
  $sel.ParagraphFormat.FirstLineIndent = -$hang
  $sel.ParagraphFormat.SpaceAfter = $after
  if ($Keep) { $sel.ParagraphFormat.KeepWithNext = -1 }
  $parts = [regex]::Split($t, '(⟦.+?⟧)')
  $spans = New-Object System.Collections.ArrayList
  foreach ($p in $parts) {
    if ($p -eq '') { continue }
    if ($p.StartsWith('⟦') -and $p.EndsWith('⟧')) {
      $s0 = $sel.Start
      $sel.TypeText((Expand-Ph $p.Substring(1, $p.Length - 2)))
      [void]$spans.Add(@($s0, $sel.Start))
    } else {
      $sel.TypeText($p)
    }
  }
  $sel.TypeParagraph()
  # convert math pieces last-to-first so earlier positions stay valid
  for ($i = $spans.Count - 1; $i -ge 0; $i--) {
    $r = $doc.Range($spans[$i][0], $spans[$i][1])
    $m = $doc.OMaths.Add($r)
    $m.OMaths.Item(1).BuildUp()
  }
  $sel.EndKey(6) | Out-Null
  Set-Normal
}

# "where:" list under an equation. Each item: @(symbol_in_UnicodeMath, meaning_text).
# An empty symbol writes the meaning as a plain note line. Meaning text may contain ⟦math⟧.
function WhereList([object[]]$items) {
  Set-Normal
  $sel.ParagraphFormat.SpaceAfter = 0
  $sel.ParagraphFormat.KeepWithNext = -1
  $sel.TypeText("where:")
  $sel.TypeParagraph()
  Reset-Para
  $n = $items.Count
  for ($i = 0; $i -lt $n; $i++) {
    $it = $items[$i]
    $after = 0; if ($i -eq $n - 1) { $after = 8 }
    if ($it[0] -eq '') { $line = $it[1] } else { $line = "⟦" + $it[0] + "⟧  –  " + $it[1] }
    BodyM $line 46 24 $after
  }
}

# Centred picture scaled to a width in points (aspect ratio kept)
function Pic([string]$path, [double]$widthPt) {
  Set-Normal
  $sel.ParagraphFormat.Alignment = 1
  $sel.ParagraphFormat.KeepWithNext = -1
  $s = $sel.InlineShapes.AddPicture($path, $false, $true)
  $s.LockAspectRatio = -1
  $s.Width = $widthPt
  $sel.EndKey(6) | Out-Null
  $sel.TypeParagraph()
  Reset-Para
}

# Report header used by every step report
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "10 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 2 (11 October 2026)")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}

# Shaded summary box (single-cell table)
function Summary([string]$t) {
  Set-Normal
  $tbl = $doc.Tables.Add($sel.Range, 1, 1)
  $tbl.Borders.Enable = 1
  $tbl.Cell(1,1).Shading.BackgroundPatternColor = 16247773
  $tbl.Range.ParagraphFormat.SpaceAfter = 4
  $tbl.Cell(1,1).Range.Text = "In short: " + $t
  $tbl.Cell(1,1).Range.Font.Size = 12
  $after = $tbl.Range.End + 1
  $sel.SetRange($after, $after)
  Set-Normal
}

# Figure heading inside the figure catalogue
function FigHead([string]$num, [string]$title) {
  Set-Normal
  $sel.ParagraphFormat.SpaceBefore = 10
  $sel.ParagraphFormat.SpaceAfter = 3
  $sel.ParagraphFormat.KeepWithNext = -1
  $sel.Font.Bold = 1
  $sel.TypeText("Figure " + $num + "  " + $title)
  $sel.TypeParagraph()
  Reset-Para
}

# "Made in:" line with the coloured environment tag
function MadeIn([string]$env, [string]$t) {
  $info = EnvInfo $env
  Set-Normal
  $sel.ParagraphFormat.LeftIndent = 21
  $sel.ParagraphFormat.SpaceAfter = 2
  $sel.Font.Bold = 1
  $sel.TypeText("Made in: ")
  $sel.Font.Color = $info[1]
  $sel.TypeText("[" + $info[0] + "]")
  $sel.Font.Color = -16777216
  $sel.Font.Bold = 0
  $sel.TypeText("  " + $t)
  $sel.TypeParagraph()
  Reset-Para
}

# Display equation, built up by Word, auto-numbered on the right.
function Eq([string]$lin) {
  Set-Normal
  $global:eqn++
  $s = Expand-Ph $lin
  $r = $sel.Range
  $r.Text = $s + "#(" + $global:eqn + ")"
  $m = $doc.OMaths.Add($r)
  $m.OMaths.Item(1).BuildUp()
  $sel.EndKey(6) | Out-Null
  $sel.TypeParagraph()
  Set-Normal
}

# Table: header row shaded and repeated on new pages; optional widths in points.
function AddTable([string[]]$headers, [object[]]$rows, [double[]]$widths) {
  Set-Normal
  $nCols = $headers.Count
  $nRows = $rows.Count + 1
  $tbl = $doc.Tables.Add($sel.Range, $nRows, $nCols)
  $tbl.Borders.Enable = 1
  $tbl.Range.Font.Size = 10.5
  $tbl.Range.ParagraphFormat.LineSpacingRule = 0
  $tbl.Range.ParagraphFormat.SpaceAfter = 2
  $tbl.Range.ParagraphFormat.SpaceBefore = 0
  $tbl.Range.ParagraphFormat.LeftIndent = 0
  $tbl.Range.ParagraphFormat.FirstLineIndent = 0
  $tbl.Range.ParagraphFormat.KeepWithNext = 0
  for ($c = 0; $c -lt $nCols; $c++) {
    $cell = $tbl.Cell(1, $c + 1)
    $cell.Range.Text = $headers[$c]
    $cell.Range.Font.Bold = 1
    $cell.Shading.BackgroundPatternColor = 14277081   # light grey
  }
  $tbl.Rows.Item(1).HeadingFormat = -1
  for ($r = 0; $r -lt $rows.Count; $r++) {
    $row = $rows[$r]
    for ($c = 0; $c -lt $nCols; $c++) { $tbl.Cell($r + 2, $c + 1).Range.Text = [string]$row[$c] }
  }
  if ($widths) {
    for ($c = 0; $c -lt $nCols; $c++) {
      $col = $tbl.Columns.Item($c + 1)
      $col.PreferredWidthType = 3
      $col.PreferredWidth = $widths[$c]
    }
  } else {
    $tbl.AutoFitBehavior(2)
  }
  $after = $tbl.Range.End + 1
  $sel.SetRange($after, $after)
  Set-Normal
  $global:lastTbl = $tbl
}

# Shade and colour the environment column of the last table
function ShadeEnv([int]$col) {
  $tbl = $global:lastTbl
  for ($r = 2; $r -le $tbl.Rows.Count; $r++) {
    $cell = $tbl.Cell($r, $col)
    $t = $cell.Range.Text
    $shade = $null; $font = $null
    if ($t -like "*CLAUDE*") { $shade = $global:S_CC; $font = $global:C_CC }
    elseif ($t -like "*MATLAB*") { $shade = $global:S_MT; $font = $global:C_MT }
    elseif ($t -like "*SIMULINK*") { $shade = $global:S_ST; $font = $global:C_ST }
    elseif ($t -like "*APPROVAL*") { $shade = $global:S_AP; $font = $global:C_AP }
    if ($shade) {
      $cell.Shading.BackgroundPatternColor = $shade
      $cell.Range.Font.Color = $font
      $cell.Range.Font.Bold = 1
    }
  }
}
