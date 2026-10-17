@echo off
rem Double-click ONCE on a new computer: creates the Python environment (06_Python_ML\.venv) and installs the pinned libraries.
rem Needs Python 3.12 installed (with "Add python.exe to PATH") and an internet connection. Takes a few minutes.
cd /d "%~dp0"
python --version
if errorlevel 1 (
    echo Python was not found. Install Python 3.12 from https://www.python.org/downloads/ and tick "Add python.exe to PATH".
    pause
    exit /b 1
)
python -m venv .venv
.venv\Scripts\python.exe -m pip install --upgrade pip
.venv\Scripts\python.exe -m pip install -r requirements.txt
echo.
echo Checking the environment...
.venv\Scripts\python.exe src\check_environment.py
echo.
echo Finished. If you see no red error text above, you can now double-click 09_API_FastAPI\Start_ML_Service.bat
pause
