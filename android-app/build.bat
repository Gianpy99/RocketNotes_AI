@echo off
REM RocketNotes AI - Quick Build Launcher
REM Launches the universal build script with default settings

echo 🚀 RocketNotes AI - Quick Build
echo =================================
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell available ✓'" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ PowerShell not found. Please install PowerShell 5.1 or higher.
    pause
    exit /b 1
)

echo Starting universal build script...
echo.

REM Launch the universal build script
powershell -ExecutionPolicy Bypass -File "build-universal.ps1" %*

echo.
echo Build completed!
pause