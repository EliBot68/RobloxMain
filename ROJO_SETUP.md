# Rojo Configuration - Standard Setup

## Standard Port: 34873

This project is configured to use **port 34873** as the standard Rojo server port.

### Quick Start

1. **Start Rojo Server:**
   ```bash
   rojo serve --port 34873
   ```
   Or simply run: `start_rojo.bat`

2. **Connect from Roblox Studio:**
   - Install the Rojo plugin in Roblox Studio
   - Connect to: `localhost:34873`

3. **VS Code Task:**
   - Use Ctrl+Shift+P → "Tasks: Run Task" → "Launch Roblox Game with Rojo"

### Build Project
```bash
rojo build --output game.rbxl
```

### Project Structure
- `src/server/` → ServerScriptService.Server
- `src/client/` → StarterPlayer.StarterPlayerScripts.Client  
- `src/shared/` → ReplicatedStorage.Shared

### Status
✅ Fully Rojo-compatible
✅ All require paths fixed
✅ Modern API compliance
✅ Live sync ready

**Server Status:** Running on localhost:34873
