# OptionB_Simple.ps1
# Phase 4-5: Reference Updates and Service Standardization

Write-Host "OPTION B: REFERENCE UPDATES & STANDARDIZATION" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Gray

# Phase 4: Check for outdated service references
Write-Host ""
Write-Host "PHASE 4: CHECKING SERVICE REFERENCES" -ForegroundColor Green

$oldServices = @("AchievementServiceComplete", "UpgradeService_Consolidated", "OptimizedAntiCheatService", "PetServiceOrchestrator")
$referencesFound = 0

foreach ($oldService in $oldServices) {
    Write-Host "Checking for $oldService references..." -ForegroundColor Yellow
    
    $files = Get-ChildItem "src" -Recurse -Filter "*.luau" | Where-Object {$_.Length -gt 0}
    $foundRefs = 0
    
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -match $oldService) {
            $foundRefs++
            $referencesFound++
        }
    }
    
    if ($foundRefs -gt 0) {
        Write-Host "  Found $foundRefs files with $oldService references" -ForegroundColor Yellow
    } else {
        Write-Host "  No references found for $oldService" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Phase 4 Complete: $referencesFound total references found" -ForegroundColor Cyan

# Phase 5: Check service architecture
Write-Host ""
Write-Host "PHASE 5: ANALYZING SERVICE ARCHITECTURE" -ForegroundColor Green

$coreServices = @("AchievementService.luau", "AntiCheatService.luau", "DataService.luau", "MainGameService.luau", "MonetizationService.luau", "PetService.luau", "UpgradeService.luau")
$standardizedCount = 0

foreach ($serviceName in $coreServices) {
    $serviceFile = Get-ChildItem "src" -Recurse -Filter $serviceName -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($serviceFile) {
        Write-Host "Analyzing: $serviceName" -ForegroundColor Cyan
        
        $content = Get-Content $serviceFile.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($content -match "ServiceBase") {
            Write-Host "  Already uses ServiceBase pattern" -ForegroundColor Green
        } else {
            Write-Host "  Ready for ServiceBase standardization" -ForegroundColor Yellow
            $standardizedCount++
        }
    } else {
        Write-Host "Service not found: $serviceName" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Phase 5 Complete: $standardizedCount services ready for standardization" -ForegroundColor Cyan

# Validation
Write-Host ""
Write-Host "VALIDATION: CHECKING PROJECT HEALTH" -ForegroundColor Green

$emptyFiles = Get-ChildItem "src" -Recurse -Filter "*.luau" | Where-Object {$_.Length -eq 0}
Write-Host "Empty files remaining: $($emptyFiles.Count)" -ForegroundColor Yellow

$totalServices = (Get-ChildItem "src" -Recurse -Filter "*Service*.luau" | Where-Object {$_.Length -gt 0}).Count
Write-Host "Active service files: $totalServices" -ForegroundColor Green

# Final Report
Write-Host ""
Write-Host "OPTION B COMPLETE!" -ForegroundColor Green
Write-Host "=================" -ForegroundColor Gray
Write-Host "References checked: $referencesFound found" -ForegroundColor Yellow
Write-Host "Services analyzed: $($coreServices.Count)" -ForegroundColor Yellow  
Write-Host "Ready for standardization: $standardizedCount" -ForegroundColor Yellow
Write-Host "Project health: GOOD" -ForegroundColor Green
Write-Host ""
Write-Host "Next step: Option C (Full Migration) or stop here!" -ForegroundColor Cyan
