# Phase3Cleanup.ps1
# Safe cleanup of empty files for Option A

Write-Host "=== PHASE 3: SAFE DUPLICATE REMOVAL ===" -ForegroundColor Cyan
Write-Host "Starting safe cleanup of empty files..." -ForegroundColor Green

# Find all empty .luau files
$emptyFiles = Get-ChildItem "src" -Recurse -Filter "*.luau" | Where-Object {$_.Length -eq 0}
Write-Host "Found $($emptyFiles.Count) empty .luau files in total" -ForegroundColor Yellow

# Categorize files for safe removal
$safeToRemove = @()
$keepFiles = @()

foreach ($file in $emptyFiles) {
    $relativePath = $file.FullName.Replace((Get-Location).Path + '\', '')
    
    # Safe to remove: Test files, documentation placeholders
    if ($file.Name -match "(Test|Framework)" -or 
        $file.Directory.Name -eq "documentation" -or
        $file.Directory.Name -eq "test") {
        $safeToRemove += $file
        Write-Host "  Safe to remove: $relativePath" -ForegroundColor Red
    } else {
        $keepFiles += $file
        Write-Host "  Keep (may be intentional): $relativePath" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Files to remove: $($safeToRemove.Count)" -ForegroundColor Red
Write-Host "  Files to keep: $($keepFiles.Count)" -ForegroundColor Yellow

# Remove safe files
$removedCount = 0
Write-Host ""
Write-Host "Removing safe files..." -ForegroundColor Green

foreach ($file in $safeToRemove) {
    try {
        $relativePath = $file.FullName.Replace((Get-Location).Path + '\', '')
        Remove-Item $file.FullName -Force
        Write-Host "  ✓ Removed: $relativePath" -ForegroundColor Green
        $removedCount++
    } catch {
        Write-Host "  ✗ Failed to remove: $relativePath - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🎉 PHASE 3 COMPLETE!" -ForegroundColor Green
Write-Host "✅ Successfully removed $removedCount empty files" -ForegroundColor Cyan
Write-Host "🛡️ Kept $($keepFiles.Count) files that may be intentionally empty" -ForegroundColor Yellow

# Show remaining empty files
if ($keepFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "📋 Remaining empty files (review manually):" -ForegroundColor Yellow
    foreach ($file in $keepFiles) {
        $relativePath = $file.FullName.Replace((Get-Location).Path + '\', '')
        Write-Host "  - $relativePath" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "🚀 Option A cleanup complete! Your project is now cleaner." -ForegroundColor Green
Write-Host "Ready for Option B (reference updates) when you're ready!" -ForegroundColor Cyan
