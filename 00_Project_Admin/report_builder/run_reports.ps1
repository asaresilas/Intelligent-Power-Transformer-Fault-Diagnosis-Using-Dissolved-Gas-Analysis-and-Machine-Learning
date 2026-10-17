$sp = "C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad"
$log = Join-Path $sp "reports_log.txt"
"START " + (Get-Date -Format T) | Out-File $log -Encoding utf8
$out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $sp "build_step_reports_01_11.ps1") 2>&1
$out | Out-File $log -Append -Encoding utf8
Get-Process WINWORD -ErrorAction SilentlyContinue | Where-Object { -not $_.MainWindowTitle } | Stop-Process -Force
"ALL_DONE " + (Get-Date -Format T) | Out-File $log -Append -Encoding utf8