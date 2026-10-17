@echo off
rem Double-click to start the DGA diagnosis service (ML model) on this computer: http://127.0.0.1:8000
rem Keep this window open while you use the dashboard. Close the window (or press Ctrl+C) to stop the service.
cd /d "%~dp0.."
if not exist "06_Python_ML\.venv\Scripts\python.exe" (
    echo The Python environment is missing. Double-click 06_Python_ML\Setup_Python_Environment.bat first.
    pause
    exit /b 1
)
echo Starting the DGA diagnosis service. Wait for the line "Uvicorn running on http://127.0.0.1:8000"
powershell -NoProfile -ExecutionPolicy Bypass -File "09_API_FastAPI\run_service.ps1"
pause
