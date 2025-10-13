# Build scripts for Firebase configuration
# These scripts help you build the Flutter app with Firebase environment variables
#
# 📋 NOTE: For comprehensive builds with Firebase support, consider using:
#    .\build-universal.ps1 -BuildType release
#    (Includes Firebase config loading, device detection, and more!)
#
# Windows PowerShell script for Android builds
param(
    [string]$BuildType = "debug"
)

Write-Host "🚀 Building RocketNotes AI with Firebase configuration..." -ForegroundColor Green

# Load environment variables from .env file
if (Test-Path ".env") {
    Write-Host "📄 Loading Firebase configuration from .env file..." -ForegroundColor Yellow
    $envContent = Get-Content ".env" | Where-Object { $_ -match '^FIREBASE_' }
    foreach ($line in $envContent) {
        if ($line -match '^([^=]+)=(.*)$') {
            $key = $matches[1]
            $value = $matches[2]
            [Environment]::SetEnvironmentVariable($key, $value)
            Write-Host "  ✓ Set $key" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "⚠️ .env file not found. Please create it with your Firebase configuration." -ForegroundColor Red
    exit 1
}

# Build Flutter app with environment variables
Write-Host "🔨 Building Flutter app ($BuildType)..." -ForegroundColor Blue

$dartDefines = @(
    "FIREBASE_API_KEY=$env:FIREBASE_API_KEY",
    "FIREBASE_AUTH_DOMAIN=$env:FIREBASE_AUTH_DOMAIN",
    "FIREBASE_PROJECT_ID=$env:FIREBASE_PROJECT_ID",
    "FIREBASE_STORAGE_BUCKET=$env:FIREBASE_STORAGE_BUCKET",
    "FIREBASE_MESSAGING_SENDER_ID=$env:FIREBASE_MESSAGING_SENDER_ID",
    "FIREBASE_APP_ID=$env:FIREBASE_APP_ID"
)

$dartDefineString = $dartDefines -join ","

if ($BuildType -eq "release") {
    flutter build apk --release --dart-define=$dartDefineString
} elseif ($BuildType -eq "appbundle") {
    flutter build appbundle --release --dart-define=$dartDefineString
} else {
    flutter build apk --debug --dart-define=$dartDefineString
}

Write-Host "✅ Build completed!" -ForegroundColor Green
