@echo off
setlocal

echo ==============================
echo PyRemote Setup Starting
echo ==============================

REM Project root (folder containing setup.bat)
set PROJECT_DIR=%~dp0
cd /d %PROJECT_DIR%

echo Project directory: %PROJECT_DIR%
echo.

REM -------------------------
REM Check Python installation
REM -------------------------
python --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Python not found.
    echo Please install Python 3.12 and try again.
    pause
    exit /b
)

for /f "tokens=2 delims= " %%v in ('python --version') do set PYVER=%%v
echo Found Python version: %PYVER%

echo %PYVER% | findstr /b "3.12" >nul
IF %ERRORLEVEL% NEQ 0 (
    echo WARNING: Python 3.12 recommended.
)

echo.
REM -------------------------
REM Create virtual environment
REM -------------------------
IF NOT EXIST "%PROJECT_DIR%venv312" (
    echo Creating virtual environment venv312...
    python -m venv venv312
) ELSE (
    echo Virtual environment venv312 already exists.
)

echo.
REM -------------------------
REM Activate venv and install dependencies
REM -------------------------
call "%PROJECT_DIR%venv312\Scripts\activate.bat"

REM Upgrade pip first
pip install --upgrade pip

REM Install requirements from pc_server_fastapi
IF EXIST "%PROJECT_DIR%pc_server_fastapi\requirements.txt" (
    echo Installing requirements from pc_server_fastapi\requirements.txt...
    pip install -r pc_server_fastapi\requirements.txt
) ELSE (
    echo WARNING: requirements.txt not found in pc_server_fastapi. Skipping dependencies.
)

echo.
REM -------------------------
REM Install PowerShell 'remote' function
REM -------------------------
for /f "delims=" %%i in ('powershell -NoProfile -Command "$PROFILE"') do set PROFILE=%%i
echo PowerShell profile: %PROFILE%

powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path (Split-Path '%PROFILE%') | Out-Null"

powershell -NoProfile -Command ^
"Add-Content -Path '%PROFILE%' -Value @'
Remove-Item function:remote -ErrorAction SilentlyContinue

function remote {
    param(
        [Parameter(ValueFromRemainingArguments=`$true)]
        `$args
    )

    `$project = ""%PROJECT_DIR%""
    `$python = ""`$project\venv312\Scripts\python.exe""
    `$script = ""`$project\pc_server_fastapi\main.py""

    & `$python `$script @args
}
'@"

echo.
echo ==============================
echo Setup Complete
echo ==============================
echo Restart PowerShell and run:
echo remote
echo.

pause