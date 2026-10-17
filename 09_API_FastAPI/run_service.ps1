# Start the DGA diagnosis service on this computer only (roadmap Step 38, decision D36).
# Run from any folder:  powershell -ExecutionPolicy Bypass -File "09_API_FastAPI\run_service.ps1"
# Stop with Ctrl+C. Check in a browser: http://127.0.0.1:8000/health  (interactive page: http://127.0.0.1:8000/docs)
$root = Split-Path -Parent $PSScriptRoot
$py = Join-Path $root "06_Python_ML\.venv\Scripts\python.exe"
& $py -I -m uvicorn --app-dir (Join-Path $root "09_API_FastAPI") app.main:app --host 127.0.0.1 --port 8000
