# Clean and rebuild script after package name change

Write-Host "🧹 Cleaning Flutter project after package name change..." -ForegroundColor Green

# Clean Flutter build artifacts
Write-Host "🗑️ Cleaning Flutter build files..." -ForegroundColor Yellow
flutter clean

# Clean Android build artifacts
Write-Host "🗑️ Cleaning Android build files..." -ForegroundColor Yellow
if (Test-Path "android") {
    Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "android\app\build" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "android\build" -Recurse -Force -ErrorAction SilentlyContinue
}

# Get Flutter dependencies
Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Blue
flutter pub get

# Build Android APK to verify everything works
Write-Host "🔨 Building debug APK to verify configuration..." -ForegroundColor Blue
flutter build apk --debug

Write-Host "✅ Project cleaned and rebuilt successfully!" -ForegroundColor Green
Write-Host "🎯 Your app is now named 'Pensieve' with package 'com.example.pensieve'" -ForegroundColor Cyan
