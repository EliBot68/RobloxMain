@echo off
echo 🔄 Pulling latest changes from GitHub...
cd /d "c:\Users\Administrator\Desktop\roblox game"
git pull origin main
echo ✅ Pull complete! 
echo 🚀 Starting Rojo server...
rojo serve
pause
