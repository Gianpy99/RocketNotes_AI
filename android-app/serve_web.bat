@echo off
echo ============================================
echo   RocketNotes AI - Web App Server
echo ============================================
echo.
echo Avvio server web locale su http://localhost:8080
echo Premi Ctrl+C per fermare il server
echo.
cd /d "%~dp0build\web"
python -m http.server 8080
pause
