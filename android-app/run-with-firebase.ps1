# Development script to run Flutter app with Firebase configuration

Write-Host "🚀 Starting RocketNotes AI with Firebase configuration..." -ForegroundColor Green

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
    Write-Host "   Copy .env.example to .env and fill in your Firebase values." -ForegroundColor Yellow
    exit 1
}

# Run Flutter app with environment variables
Write-Host "🔥 Starting Flutter app with Firebase..." -ForegroundColor Blue

$dartDefines = @(
    "FIREBASE_API_KEY=$env:FIREBASE_API_KEY",
    "FIREBASE_AUTH_DOMAIN=$env:FIREBASE_AUTH_DOMAIN",
    "FIREBASE_PROJECT_ID=$env:FIREBASE_PROJECT_ID",
    "FIREBASE_STORAGE_BUCKET=$env:FIREBASE_STORAGE_BUCKET",
    "FIREBASE_MESSAGING_SENDER_ID=$env:FIREBASE_MESSAGING_SENDER_ID",
    "FIREBASE_APP_ID=$env:FIREBASE_APP_ID"
)

$dartDefineString = $dartDefines -join ","

flutter run --dart-define=$dartDefineString

Write-Host "✅ App stopped." -ForegroundColor Green
