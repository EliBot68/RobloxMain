@echo off
echo.
echo ========================================
echo   ROJO DEVELOPMENT SERVER LAUNCHER
echo ========================================
echo.
echo Choose your development mode:
echo.
echo [1] STREAMLINED - Fast live sync (recommended for active development)
echo [2] COMPLETE - Full project build only (for final builds)
echo [3] STOP - Stop all Rojo servers
echo.
set /p choice="Enter your choice (1, 2, or 3): "

if "%choice%"=="1" (
    echo.
    echo Starting STREAMLINED live sync server...
    echo Port: 34873
    echo Files: Core development files only
    echo Performance: FAST live sync
    echo.
    rojo serve streamlined.project.json --port 34873
) else if "%choice%"=="2" (
    echo.
    echo Building COMPLETE project...
    echo This includes all 590+ files
    echo.
    rojo build default.project.json --output CompleteGame.rbxl
    echo.
    echo ✅ Complete build saved as CompleteGame.rbxl
    pause
) else if "%choice%"=="3" (
    echo.
    echo Stopping all Rojo servers...
    powershell -Command "Get-Process -Name 'rojo' -ErrorAction SilentlyContinue | Stop-Process -Force"
    echo ✅ All servers stopped
    pause
) else (
    echo.
    echo Invalid choice. Please run again and select 1, 2, or 3.
    pause
)
