# add_platform_tools.ps1
# Cerca posizioni comuni dell'Android SDK e aggiunge platform-tools+emulator al PATH utente
param()

$possible = @()
if ($env:ANDROID_SDK_ROOT) { $possible += $env:ANDROID_SDK_ROOT }
if ($env:ANDROID_HOME) { $possible += $env:ANDROID_HOME }
$possible += "$env:LOCALAPPDATA\Android\Sdk"
$possible += 'C:\Android\sdk'
$possible += 'C:\Program Files\Android\Sdk'
$possible += 'C:\Program Files (x86)\Android\Sdk'

Write-Host 'Checking common Android SDK locations...'
$found = $null
foreach ($p in $possible) {
    if ($p -and (Test-Path (Join-Path $p 'platform-tools'))) {
        $found = $p; break
    }
}

if (-not $found) {
    Write-Host 'No Android SDK with platform-tools found.' -ForegroundColor Yellow
    Write-Host 'Paths checked:'
    $possible | ForEach-Object { Write-Host " - $_" }
    exit 2
}

$platform = Join-Path $found 'platform-tools'
$emulator = Join-Path $found 'emulator'

Write-Host "Found Android SDK at: $found"
Write-Host "platform-tools: $platform"
Write-Host "emulator: $emulator"

# Ensure ANDROID_SDK_ROOT is set for the user
try {
    $currentSdkRoot = [Environment]::GetEnvironmentVariable('ANDROID_SDK_ROOT','User')
    if (-not $currentSdkRoot -or $currentSdkRoot -ne $found) {
        [Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $found, 'User')
        Write-Host "Set User ANDROID_SDK_ROOT to: $found" -ForegroundColor Green
    } else {
        Write-Host "User ANDROID_SDK_ROOT already set to: $currentSdkRoot" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Could not set ANDROID_SDK_ROOT: $_" -ForegroundColor Yellow
}

# Add platform-tools and emulator to User PATH if missing (do not duplicate entries)
$current = [Environment]::GetEnvironmentVariable('PATH','User')
if (-not $current) { $current = '' }
$need = @()
if ($current -notlike "*${platform}*" -and (Test-Path $platform)) { $need += $platform }
if ($current -notlike "*${emulator}*" -and (Test-Path $emulator)) { $need += $emulator }

if ($need.Count -gt 0) {
    $new = $current
    if (-not [string]::IsNullOrEmpty($new)) { $new += ';' }
    $new += ($need -join ';')
    try {
        [Environment]::SetEnvironmentVariable('PATH', $new, 'User')
        Write-Host 'Updated User PATH to include:' -ForegroundColor Green
        $need | ForEach-Object { Write-Host " - $_" }
        Write-Host 'Note: Restart VS Code / terminals to use the new PATH.'
    } catch {
        Write-Host "Failed to update User PATH: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host 'platform-tools and emulator already appear in User PATH.' -ForegroundColor Cyan
}

Write-Host "where.exe adb:" 
$where = (where.exe adb) 2>$null
if ($where) { $where | ForEach-Object { Write-Host " - $_" } } else { Write-Host '(adb not found in PATH yet)' -ForegroundColor Yellow }

Write-Host 'Done.'
