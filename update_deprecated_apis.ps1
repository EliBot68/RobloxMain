# PowerShell script to update deprecated Roblox API usage
# This script replaces wait() with task.wait() and spawn() with task.spawn()

Write-Host "🔧 Starting deprecated API update..." -ForegroundColor Green

$sourceDir = "src"
$luauFiles = Get-ChildItem -Path $sourceDir -Filter "*.luau" -Recurse
$totalFiles = $luauFiles.Count
$processedFiles = 0
$changedFiles = 0

Write-Host "📁 Found $totalFiles .luau files to process" -ForegroundColor Cyan

foreach ($file in $luauFiles) {
    $processedFiles++
    $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
    Write-Progress -Activity "Processing Files" -Status "Processing $relativePath" -PercentComplete (($processedFiles / $totalFiles) * 100)
    
    try {
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content
        
        # Common wait() patterns - be specific to avoid breaking function definitions
        $content = $content -replace '\bwait\(([^)]+)\)(\s*--[^\r\n]*)?', 'task.wait($1) -- UPDATED for modern API$2'
        
        # Simple wait() calls without parameters
        $content = $content -replace '\bwait\(\)(\s*--[^\r\n]*)?', 'task.wait() -- UPDATED for modern API$1'
        
        # spawn() function calls
        $content = $content -replace '\bspawn\(', 'task.spawn( -- UPDATED for modern API'
        
        # Fix cases where we added double comments
        $content = $content -replace '-- UPDATED for modern API(\s*--[^\r\n]*-- UPDATED for modern API)', '$1'
        
        # RunService.Heartbeat:Wait() should remain as is (it's not deprecated)
        # Just add a comment to clarify it's intentional
        $content = $content -replace 'RunService\.Heartbeat:Wait\(\)', 'RunService.Heartbeat:Wait() -- Intentionally not using task.wait()'
        
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            $changedFiles++
            Write-Host "✅ Updated: $relativePath" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Error processing $relativePath : $_" -ForegroundColor Red
    }
}

Write-Host "`n🎉 Deprecated API update complete!" -ForegroundColor Green
Write-Host "📊 Files processed: $processedFiles" -ForegroundColor Cyan
Write-Host "📊 Files changed: $changedFiles" -ForegroundColor Cyan
Write-Host "`n🔍 Summary of changes made:" -ForegroundColor Yellow
Write-Host "  • wait() → task.wait() -- UPDATED for modern API" -ForegroundColor White
Write-Host "  • spawn() → task.spawn() -- UPDATED for modern API" -ForegroundColor White
Write-Host "  • RunService.Heartbeat:Wait() left unchanged (not deprecated)" -ForegroundColor White
