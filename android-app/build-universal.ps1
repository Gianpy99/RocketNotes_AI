# RocketNotes AI - Universal Build Script
# PowerShell script for building APK for phone installation and emulator testing

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("debug", "release", "profile")]
    [string]$BuildType = "debug",

    [Parameter(Mandatory=$false)]
    [ValidateSet("phone", "emulator", "both", "test")]
    [string]$Target = "both",

    [switch]$Clean,
    [switch]$NoInstall,
    [switch]$RunTests,
    [switch]$Help
)

# Display help
if ($Help) {
    Write-Host "RocketNotes AI Build Script" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\build-universal.ps1 [options]" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -BuildType <type>    Build type: debug (default), release, profile" -ForegroundColor White
    Write-Host "  -Target <target>     Target: phone, emulator, both (default), test" -ForegroundColor White
    Write-Host "  -Clean               Clean build cache before building" -ForegroundColor White
    Write-Host "  -NoInstall           Build only, don't install" -ForegroundColor White
    Write-Host "  -RunTests            Run integration tests after build" -ForegroundColor White
    Write-Host "  -Help                Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\build-universal.ps1                          # Build debug for both phone and emulator" -ForegroundColor White
    Write-Host "  .\build-universal.ps1 -BuildType release       # Build release APK" -ForegroundColor White
    Write-Host "  .\build-universal.ps1 -Target phone            # Build for phone only" -ForegroundColor White
    Write-Host "  .\build-universal.ps1 -Target emulator -RunTests # Build for emulator and run tests" -ForegroundColor White
    Write-Host "  .\build-universal.ps1 -Clean -BuildType release # Clean and build release" -ForegroundColor White
    Write-Host ""
    exit 0
}

# Configuration
$ProjectName = "RocketNotes AI"
$ApkPath = "build\app\outputs\flutter-apk\app-$BuildType.apk"

# Colors for output
$Green = "Green"
$Cyan = "Cyan"
$Yellow = "Yellow"
$Red = "Red"
$White = "White"

function Write-Step {
    param([string]$Message)
    Write-Host "STEP: $Message" -ForegroundColor $Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "SUCCESS: $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "WARNING: $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor $Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "INFO: $Message" -ForegroundColor $White
}

# Header
Write-Host "$ProjectName - Universal Build Script" -ForegroundColor $Cyan
Write-Host "======================================" -ForegroundColor $Cyan
Write-Host "Build Type: $BuildType | Target: $Target" -ForegroundColor $Yellow
Write-Host ""

# Check prerequisites
Write-Step "Checking prerequisites..."

# Check Flutter
try {
    $flutterVersion = flutter --version | Select-Object -First 1
    Write-Success "Flutter found: $flutterVersion"
} catch {
    Write-Error "Flutter not found. Please install Flutter SDK."
    exit 1
}

# Check ADB
try {
    $adbVersion = adb version | Select-Object -First 1
    Write-Success "ADB found: $adbVersion"
} catch {
    Write-Warning "ADB not found. Install Android SDK or Android Studio."
}

Write-Host ""

# Clean if requested
if ($Clean) {
    Write-Step "Cleaning build cache..."
    flutter clean
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Clean failed, continuing anyway..."
    } else {
        Write-Success "Build cache cleaned"
    }
}

# Load Firebase config if available
$dartDefineString = ""
$dartDefines = @()
if (Test-Path ".env") {
    Write-Step "Loading Firebase configuration..."
    try {
        $envContent = Get-Content ".env" | Where-Object { $_ -match '^FIREBASE_' }
        $dartDefines = @()
        foreach ($line in $envContent) {
                    if ($line -match '^([^=]+)=(.*)$') {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    # Remove surrounding quotes if present
                    if ($value -match '^"(.*)"$') { $value = $matches[1] }
                    [Environment]::SetEnvironmentVariable($key, $value)
                    $dartDefines += "$key=$value"
                    Write-Info "  Loaded $key"
                }
        }
        $dartDefineString = $dartDefines -join ","
        Write-Success "Firebase config loaded"
    } catch {
        Write-Warning "Failed to load .env file"
    }
} else {
    Write-Info "No .env file found, skipping Firebase config"
}

# Build APK
Write-Step "Building $BuildType APK..."
# Build arguments array to safely append multiple --dart-define flags
$buildArgs = @("build","apk","--$BuildType")

# Add dart-define entries as separate flags
if ($dartDefines -and $dartDefines.Count -gt 0) {
    foreach ($d in $dartDefines) {
        $trimmed = $d.Trim()
        if ($trimmed -ne "") {
            $buildArgs += "--dart-define=$trimmed"
        }
    }
} elseif ($dartDefineString -and $dartDefineString.Trim() -ne "") {
    # Fallback: if legacy single string exists, append it as-is
    $buildArgs += "--dart-define=$($dartDefineString.Trim())"
}

Write-Info "Command: flutter " + ($buildArgs -join " ")
# Invoke flutter with argument array to avoid shell tokenization issues
& flutter @buildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

# Check if APK was created
if (-not (Test-Path $ApkPath)) {
    Write-Error "APK not found at $ApkPath"
    exit 1
}

$apkSize = (Get-Item $ApkPath).Length / 1MB
Write-Success "APK built successfully ($("{0:N2}" -f $apkSize) MB)"

# Handle different targets
switch ($Target) {
    "phone" {
        if (-not $NoInstall) {
            Write-Step "Installing on connected phone..."
            Install-OnDevice "phone"
        }
    }
    "emulator" {
        if (-not $NoInstall) {
            Write-Step "Installing on emulator..."
            Install-OnDevice "emulator"
        }
        if ($RunTests) {
            Write-Step "Running integration tests..."
            Invoke-IntegrationTests
        }
    }
    "both" {
        if (-not $NoInstall) {
            Write-Step "Installing on all connected devices..."
            Install-OnDevice "both"
        }
        if ($RunTests) {
            Write-Step "Running integration tests..."
            Invoke-IntegrationTests
        }
    }
    "test" {
        Write-Step "Running tests only..."
        Invoke-IntegrationTests
    }
}

# Functions
function Install-OnDevice {
    param([string]$deviceType)

    # Get connected devices
    $devicesOutput = adb devices
    $deviceLines = $devicesOutput | Select-Object -Skip 1 | Where-Object { $_ -and $_ -notmatch "^\*" }

    if (-not $deviceLines) {
        Write-Warning "No devices connected"
        return
    }

    $deviceCount = 0
    foreach ($line in $deviceLines) {
        if ($line -match '^(\S+)\s+(\w+)$') {
            $deviceId = $matches[1]
            $deviceState = $matches[2]

            if ($deviceState -eq "device") {
                $deviceInfo = adb -s $deviceId shell getprop ro.product.model 2>$null
                $deviceInfo = $deviceInfo -replace '\r?\n', ''

                if ($deviceType -eq "both" -or
                    ($deviceType -eq "emulator" -and $deviceId -match "^emulator-") -or
                    ($deviceType -eq "phone" -and $deviceId -notmatch "^emulator-")) {

                    Write-Info "Installing on $deviceInfo ($deviceId)..."
                    $installResult = adb -s $deviceId install -r $ApkPath 2>&1

                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "Installed on $deviceInfo"
                        $deviceCount++
                    } else {
                        Write-Error "Failed to install on $deviceInfo : $installResult"
                    }
                }
            }
        }
    }

    if ($deviceCount -eq 0) {
        Write-Warning "No suitable $deviceType devices found"
        Write-Info "Make sure your device is connected and USB debugging is enabled"
        Write-Info "For emulator: Start Android Studio AVD Manager"
    } else {
        Write-Success "Installed on $deviceCount device(s)"
    }
}

function Invoke-IntegrationTests {
    Write-Step "Running integration tests..."

    # Check if emulator is running
    $devicesOutput = adb devices
    $emulatorFound = $devicesOutput | Select-String "emulator-"

    if (-not $emulatorFound) {
        Write-Warning "No emulator found. Starting emulator..."
        Write-Info "Please start your emulator manually or use Android Studio AVD Manager"
        return
    }

    # Run Flutter integration tests
    Write-Info "Running Flutter integration tests..."
    flutter test integration_test/
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Integration tests passed"
    } else {
        Write-Error "Integration tests failed"
    }
}

# Footer
Write-Host ""
Write-Host "Build process completed!" -ForegroundColor $Green
Write-Host "APK Location: $ApkPath" -ForegroundColor $Cyan

if ($Target -in @("phone", "emulator", "both") -and -not $NoInstall) {
    Write-Host "APK installed on connected device(s)" -ForegroundColor $Cyan
}

if ($RunTests) {
    Write-Host "Tests executed" -ForegroundColor $Cyan
}

Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor $Yellow
Write-Host "  - Test the app on your device" -ForegroundColor $White
Write-Host "  - Add widgets to home screen (long press -> Widgets -> Pensieve)" -ForegroundColor $White
Write-Host "  - Run .\test-widgets.ps1 to test widget functionality" -ForegroundColor $White
Write-Host ""
Write-Host "DOCUMENTATION:" -ForegroundColor $Yellow
Write-Host "  - Installation: INSTALLAZIONE_APK.md" -ForegroundColor $White
Write-Host "  - Widgets: docs/WIDGET_VISUAL_GUIDE.md" -ForegroundColor $White
Write-Host "  - Commands: docs/WIDGET_QUICK_COMMANDS.md" -ForegroundColor $White