param([string]$docx, [string]$outDir, [string]$prefix, [int]$first = 1, [int]$last = 999, [int]$widthPx = 1100)
# Renders Word pages to PNG via each page's enhanced metafile (avoids Word's PDF export).
Add-Type -AssemblyName System.Drawing
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$d = $word.Documents.Open($docx, $false, $true)
$d.ActiveWindow.View.Type = 3          # print layout
$d.Repaginate()
$pages = $d.ActiveWindow.ActivePane.Pages
$n = $pages.Count
if ($last -gt $n) { $last = $n }
for ($i = $first; $i -le $last; $i++) {
  $bits = [byte[]]$pages.Item($i).EnhMetaFileBits
  $ms = New-Object IO.MemoryStream(, $bits)
  $mf = New-Object System.Drawing.Imaging.Metafile($ms)
  $h = [int]($widthPx * $mf.Height / $mf.Width)
  $bmp = New-Object System.Drawing.Bitmap($widthPx, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::White)
  $g.SmoothingMode = 'HighQuality'
  $g.TextRenderingHint = 'AntiAliasGridFit'
  $g.DrawImage($mf, 0, 0, $widthPx, $h)
  $png = Join-Path $outDir ("{0}_p{1:D2}.png" -f $prefix, $i)
  $bmp.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose(); $mf.Dispose(); $ms.Dispose()
}
"pages_total=$n rendered=$first-$last"
$d.Close($false)
$word.Quit()
