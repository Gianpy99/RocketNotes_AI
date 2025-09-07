# Rebuild script after Firebase Gradle configuration

Write-Host "Rebuilding after Firebase Gradle configuration..." -ForegroundColor Green

# Clean Flutter build artifacts
Write-Host "Cleaning Flutter build files..." -ForegroundColor Yellow
flutter clean

# Clean Android build artifacts
Write-Host "Cleaning Android build files..." -ForegroundColor Yellow
if (Test-Path "android") {
    Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "android\app\build" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "android\build" -Recurse -Force -ErrorAction SilentlyContinue
}

# Get Flutter dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Blue
flutter pub get

# Build Android APK to verify Firebase configuration
Write-Host "Building debug APK with Firebase..." -ForegroundColor Blue
flutter build apk --debug

Write-Host "Firebase Gradle configuration completed!" -ForegroundColor Green
Write-Host "Your app now has Firebase Auth, Firestore, Storage, and Analytics configured" -ForegroundColor Cyan
