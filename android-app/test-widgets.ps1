# Test Widget Deep Links
# Script per testare i widget Android via ADB

Write-Host "🧪 Testing RocketNotes AI Widgets" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Verifica che ADB sia disponibile
$adbPath = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adbPath) {
    Write-Host "❌ ADB not found. Please install Android SDK Platform Tools" -ForegroundColor Red
    exit 1
}

Write-Host "✅ ADB found at: $($adbPath.Source)" -ForegroundColor Green
Write-Host ""

# Verifica dispositivi connessi
Write-Host "📱 Checking connected devices..." -ForegroundColor Yellow
$devices = adb devices
Write-Host $devices
Write-Host ""

$packageName = "com.example.pensieve"

# Menu di scelta
Write-Host "Select widget to test:" -ForegroundColor Cyan
Write-Host "1. 📷 Camera Widget (rocketnotes://camera)"
Write-Host "2. 🎤 Audio Widget (rocketnotes://audio)"
Write-Host "3. 🧪 Test both widgets"
Write-Host "4. 📦 Build and install APK"
Write-Host "5. ❌ Exit"
Write-Host ""

$choice = Read-Host "Enter your choice (1-5)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "🚀 Testing Camera Widget..." -ForegroundColor Yellow
        adb shell am start -W -a android.intent.action.VIEW -d "rocketnotes://camera" $packageName
        Write-Host "✅ Camera deep link sent" -ForegroundColor Green
    }
    "2" {
        Write-Host ""
        Write-Host "🚀 Testing Audio Widget..." -ForegroundColor Yellow
        adb shell am start -W -a android.intent.action.VIEW -d "rocketnotes://audio" $packageName
        Write-Host "✅ Audio deep link sent" -ForegroundColor Green
    }
    "3" {
        Write-Host ""
        Write-Host "🚀 Testing Camera Widget..." -ForegroundColor Yellow
        adb shell am start -W -a android.intent.action.VIEW -d "rocketnotes://camera" $packageName
        Start-Sleep -Seconds 2
        
        Write-Host "🚀 Testing Audio Widget..." -ForegroundColor Yellow
        adb shell am start -W -a android.intent.action.VIEW -d "rocketnotes://audio" $packageName
        Write-Host "✅ Both deep links tested" -ForegroundColor Green
    }
    "4" {
        Write-Host ""
        Write-Host "📦 Building APK..." -ForegroundColor Yellow
        Set-Location -Path "android-app"
        flutter clean
        flutter pub get
        flutter build apk --debug
        
        Write-Host ""
        Write-Host "📲 Installing APK..." -ForegroundColor Yellow
        $apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
        adb install -r $apkPath
        
        Write-Host "✅ APK installed successfully" -ForegroundColor Green
        Set-Location -Path ".."
    }
    "5" {
        Write-Host "👋 Goodbye!" -ForegroundColor Cyan
        exit 0
    }
    default {
        Write-Host "❌ Invalid choice" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "💡 Tip: Check Android Studio Logcat for debug messages:" -ForegroundColor Cyan
Write-Host "   - Look for: '📱 Widget initial link'"
Write-Host "   - Look for: '🔗 Handling widget link'"
Write-Host "   - Look for: '✅ Navigated to'"
Write-Host ""
Write-Host "📚 For more info, see: docs/implementation/ANDROID_WIDGETS.md" -ForegroundColor Cyan
