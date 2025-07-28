# 🎮 STEP-BY-STEP: Connect Your Repo to Roblox Studio

## 📋 **What You Need:**
- ✅ Roblox Studio installed
- ✅ Your project folder: `c:\Users\Administrator\Desktop\roblox game`
- ✅ Command Prompt or PowerShell

## 🔌 **Step 1: Install Rojo Plugin**

1. **Open Roblox Studio**
2. **Click the "PLUGINS" tab** at the top
3. **Click "Plugins" button** in the toolbar
4. **Search for "Rojo"** in the toolbox window
5. **Install the official Rojo plugin** (look for the Roblox logo)
6. **Close the toolbox** - you should see a **Rojo button** in your plugins toolbar

## ⚡ **Step 2: Start Rojo Server**

### **Option A: Double-click the batch file**
1. Navigate to: `c:\Users\Administrator\Desktop\roblox game`
2. **Double-click `start_rojo.bat`**
3. A black command window should open and show "Rojo server running..."

### **Option B: Use Command Prompt**
1. **Press Windows Key + R**
2. **Type `cmd` and press Enter**
3. **Copy and paste this command:**
   ```
   cd "c:\Users\Administrator\Desktop\roblox game" && rojo serve
   ```
4. **Press Enter**
5. You should see: `Rojo server listening on port 34872`

## 🔗 **Step 3: Connect Studio to Rojo**

1. **In Roblox Studio, click the "Rojo" button** in the plugins toolbar
2. **A Rojo window will appear**
3. **Click "Connect"** (it should connect to localhost:34872)
4. **You should see "Connected" status**
5. **Click "Sync In"** to load all your files

## 🎉 **Step 4: Verify Everything Loaded**

After clicking "Sync In", you should see in Studio:

### **ServerScriptService:**
- 📁 Server folder (with all your server scripts)
- 📄 MainGameController.luau
- 📁 services folder
- 📁 controllers folder

### **StarterPlayer > StarterPlayerScripts:**
- 📁 Client folder (with all your client scripts)
- 📄 PlayerMovementController.client.luau
- 📄 GameTimerUIController.client.luau

### **ReplicatedStorage:**
- 📁 Shared folder (with shared modules)
- 📁 RemoteEvents folder

## 🎮 **Step 5: Test Your Game**

1. **Press F5** or click the **Play** button in Studio
2. Your Color Rush game should start!
3. **Controls:**
   - **WASD** to move
   - **1, 2, 3** to change colors
   - **Goal:** Match your color to track segments

## ⚠️ **Troubleshooting**

### **If Rojo won't connect:**
- Make sure the command window is still open and showing "listening on port 34872"
- Try closing and reopening Roblox Studio
- Click the Rojo button again and try "Connect"

### **If files don't appear:**
- Make sure you clicked "Sync In" after connecting
- Check that you're in the correct folder: `c:\Users\Administrator\Desktop\roblox game`
- Try disconnecting and reconnecting

### **If you get errors:**
- Make sure Rojo is installed: open command prompt and type `rojo --version`
- If not installed, run: `scoop install rojo` (if you have Scoop) or download from rojo.space

## 🏆 **Success!**

Once connected, you have:
- ✅ Complete Color Rush game loaded in Studio
- ✅ 60-second timer gameplay
- ✅ Xbox controller support
- ✅ Colorblind accessibility features
- ✅ Professional, comfortable colors
- ✅ All 184+ script files synced

**Your game is ready to test and publish!** 🚀

---

**Need help? The Rojo server must stay running in the command window while you work in Studio.**
