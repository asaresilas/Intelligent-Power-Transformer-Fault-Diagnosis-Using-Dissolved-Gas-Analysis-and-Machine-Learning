# Stop whatever listens on 127.0.0.1:8000 (the DGA diagnosis service, also a hung one) - 15 Oct 2026.
# Ends the listening process and, when its parent is a python.exe (venv launcher) or cmd.exe (detached start), that parent too.
# Any other parent (for example the WMI host) is left alone. Prints the number of processes stopped. Safe when nothing runs.
$n = 0
$conns = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
foreach ($c in $conns) {
    $p = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $c.OwningProcess)
    if ($p) {
        $pp = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $p.ParentProcessId)
        if ($pp -and ($pp.Name -eq 'python.exe' -or $pp.Name -eq 'cmd.exe')) {
            Stop-Process -Id $pp.ProcessId -Force -ErrorAction SilentlyContinue; $n++
        }
    }
    Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue; $n++
}
Write-Output "STOPPED $n"
