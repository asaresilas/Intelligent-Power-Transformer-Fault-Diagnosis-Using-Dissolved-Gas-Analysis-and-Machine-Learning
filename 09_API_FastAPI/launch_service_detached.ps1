# Start the DGA diagnosis service FULLY DETACHED from the program that calls this script (used by the MATLAB dashboard, 15 Oct 2026).
#
# WHY THIS FILE EXISTS (freeze found 15 Oct 2026): when MATLAB started run_service.ps1 with system(), the service inherited MATLAB's
# output pipe (4 KB buffer). uvicorn writes one log line per request; after about 60 requests the pipe was full, nobody read it,
# the service blocked on its next log write and MATLAB waited for it without end (one call waited 248 s).
# This script therefore (1) creates the process through WMI (Win32_Process.Create), which gives the new process NO handles of the
# caller, (2) sends all output to 09_API_FastAPI\logs\service.log and (3) switches the per-request access log off.
# It returns at once; the dashboard then polls http://127.0.0.1:8000/health.
#
# Run by hand:  powershell -NoProfile -ExecutionPolicy Bypass -File "09_API_FastAPI\launch_service_detached.ps1"
# Stop:         MATLAB stop_ml_service, or close the dashboard (it stops a service that it started itself).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$py   = Join-Path $root '06_Python_ML\.venv\Scripts\python.exe'
$app  = Join-Path $root '09_API_FastAPI'
$logd = Join-Path $app 'logs'
if (-not (Test-Path $py)) { Write-Output "ERROR: Python environment missing: $py"; exit 2 }
if (-not (Test-Path $logd)) { New-Item -ItemType Directory -Path $logd | Out-Null }
$log = Join-Path $logd 'service.log'
if ((Test-Path $log) -and ((Get-Item $log).Length -gt 1MB)) { Move-Item $log (Join-Path $logd 'service_previous.log') -Force }
$inner = '"' + $py + '" -I -m uvicorn --app-dir "' + $app + '" app.main:app --host 127.0.0.1 --port 8000 --no-access-log --log-level warning'
$cmd = 'cmd.exe /c "' + $inner + ' >> "' + $log + '" 2>&1"'
$r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd; CurrentDirectory = $app }
if ($r.ReturnValue -ne 0) { Write-Output "ERROR: could not create the process (code $($r.ReturnValue))"; exit 3 }
Write-Output "STARTED pid $($r.ProcessId)"
