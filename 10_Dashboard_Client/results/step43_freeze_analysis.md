# Why the dashboard froze - analysis of 15 October 2026

Measured in this session (MATLAB R2025b, Windows 11, one computer). Nothing below is estimated.

## What was observed
1. At the start of the session the FastAPI service (PID 19660, started at 10:35 by the dashboard) owned port 8000 but did not answer:
   `webread('http://127.0.0.1:8000/health')` timed out after 3 s ("Waiting for response header"); the connection list showed `Listen` and `CloseWait`.
2. Reproduction. Old `ensure_ml_service` (started the service with `system('start "" /B powershell ... run_service.ps1')`), then 400 calls of `ml_diagnose`:
   - service started in 6 s;
   - requests 1-61: answered;
   - request 62: **waited 248.4 s** (until the service processes were killed from outside), then failed `NOT_CONNECTED`; requests 63 and 64 failed after 2 s;
   - during the wait MATLAB itself did not respond (the next MATLAB command was queued behind it): this is the "frozen software".

## Cause
`system()` hands MATLAB's output pipe to the program it starts. The hidden service inherited that pipe. uvicorn prints one access-log line per request
(about 70 bytes); the pipe buffer of 4 KB was full after about 60 requests, nobody reads it, the service blocks while writing the next log line and
stops answering. A second weakness made it worse: a hung service still owns port 8000, so a new service could never start, and the old code waited
90 s for it.

## Fix (files)
| Change | File |
|---|---|
| Service started through WMI (`Win32_Process.Create`): no inherited handles; all output to `09_API_FastAPI/logs/service.log`; per-request access log off | `09_API_FastAPI/launch_service_detached.ps1` |
| A service that owns the port but does not answer is stopped and replaced; every wait is short and reported | `10_Dashboard_Client/ensure_ml_service.m` |
| Safe stop (service process and its python/cmd parent only) | `09_API_FastAPI/stop_service.ps1`, `10_Dashboard_Client/stop_ml_service.m` |
| Dashboard: health check before every diagnosis (restart if needed), busy lock on the buttons, progress windows, model warm-up at start, "Restart ML service" button, service stopped when the app that started it is closed | `10_Dashboard_Client/tools/DGADashboard_code.txt` -> `DGADashboard.mlapp` |

## Second cause of "looks frozen": the cold first run
The first simulation in a fresh MATLAB session (Simulink/Simscape compile) took 54.4 s of a full run with no message on screen (a warm run: 12.4 s;
the simulation alone: 3.3 s). The model is now prepared during start-up behind a progress window ("first start only, up to 1 minute").

## After the fix
Same test, new start: 400 of 400 requests answered, none failed, median 76 ms (verify_step43, checks A1-A3). Recovery from a hung service (a dummy
listener that accepts connections and never answers): replaced by a working service in 15 s (check B).
