@echo off
echo Starting Enterprise Color Rush Rojo Server...
cd /d "c:\Users\Administrator\Desktop\robloxmain2"
echo Building project first...
rojo build --output "build.rbxlx"
if %errorlevel% equ 0 (
    echo Build successful! Starting server...
    rojo serve --port 34874
) else (
    echo Build failed! Check project configuration.
    pause
)
pause
