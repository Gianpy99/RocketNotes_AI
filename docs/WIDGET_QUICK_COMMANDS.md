# 🚀 Quick Commands - Android Widgets

## Build & Deploy

### Clean Build
```powershell
cd c:\Development\RocketNotes_AI\android-app
flutter clean
flutter pub get
flutter build apk --debug
```

### Install on Device
```powershell
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

### One-Command Build & Install
```powershell
cd c:\Development\RocketNotes_AI\android-app ; flutter clean ; flutter pub get ; flutter build apk --debug ; adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

## Testing

### Automated Widget Test
```powershell
cd c:\Development\RocketNotes_AI\android-app
.\test-widgets.ps1
```

### Manual Deep Link Test (ADB)

**Test Camera Widget:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "rocketnotes://camera" com.example.pensieve
```

**Test Audio Widget:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "rocketnotes://audio" com.example.pensieve
```

**Test Both:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "rocketnotes://camera" com.example.pensieve ; Start-Sleep -Seconds 2 ; adb shell am start -W -a android.intent.action.VIEW -d "rocketnotes://audio" com.example.pensieve
```

## Debugging

### View Logcat
```bash
# All logs
adb logcat

# Filter widget/deeplink logs
adb logcat | grep -i "widget\|deeplink\|rocketnotes"

# Filter Flutter logs
adb logcat | grep -i "flutter"

# Clear and start fresh
adb logcat -c ; adb logcat
```

### Check Device
```bash
# List connected devices
adb devices

# Device info
adb shell getprop ro.build.version.sdk
```

### Check App State
```bash
# List installed packages
adb shell pm list packages | grep rocket

# App info
adb shell dumpsys package com.example.pensieve | grep version

# Clear app data
adb shell pm clear com.example.pensieve
```

## Widget Management

### List Widgets
```bash
# List all app widgets
adb shell dumpsys appwidget

# List only Pensieve widgets
adb shell dumpsys appwidget | grep -A 20 pensieve
```

### Force Widget Update
```bash
# Broadcast update intent
adb shell am broadcast -a android.appwidget.action.APPWIDGET_UPDATE -n com.example.pensieve/.CameraWidgetProvider

adb shell am broadcast -a android.appwidget.action.APPWIDGET_UPDATE -n com.example.pensieve/.AudioWidgetProvider
```

## Development

### Hot Reload (doesn't work for widgets)
```bash
# Hot reload (only Flutter changes)
r

# Hot restart (all changes except native)
R
```

**Note**: Widget changes require full rebuild:
```powershell
flutter build apk --debug ; adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

### Code Analysis
```bash
# Analyze code
flutter analyze

# Fix issues
dart fix --apply

# Format code
dart format .
```

## File Locations

### Widget Files (Android)
```
android/app/src/main/
├── kotlin/com/example/pensieve/
│   ├── CameraWidgetProvider.kt
│   └── AudioWidgetProvider.kt
├── res/
│   ├── xml/camera_widget_info.xml
│   ├── xml/audio_widget_info.xml
│   ├── layout/camera_widget_layout.xml
│   └── layout/audio_widget_layout.xml
└── AndroidManifest.xml
```

### Widget Files (Flutter)
```
lib/
├── data/services/widget_deep_link_service.dart
├── app/routes_simple.dart
└── presentation/screens/home_screen.dart
```

## Quick Edits

### Change Widget Color
```xml
<!-- android/app/src/main/res/drawable/widget_background.xml -->
<solid android:color="#673AB7" />  <!-- Change this -->
```

### Change Widget Size
```xml
<!-- android/app/src/main/res/xml/*_widget_info.xml -->
android:minWidth="80dp"        <!-- Change this -->
android:minHeight="80dp"       <!-- Change this -->
android:targetCellWidth="2"    <!-- Change this -->
android:targetCellHeight="2"   <!-- Change this -->
```

### Add New Deep Link
```dart
// lib/app/routes_simple.dart
GoRoute(
  path: '/newaction',
  builder: (context, state) => const NewActionScreen(),
),
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="rocketnotes" android:host="newaction" />
</intent-filter>
```

## Troubleshooting Commands

### Widget Not Showing
```powershell
# Full rebuild
flutter clean
flutter pub get
flutter build apk --debug
adb uninstall com.example.pensieve
adb install -r build\app\outputs\flutter-apk\app-debug.apk
# Then reboot device
adb reboot
```

### Widget Not Responding
```bash
# Check if PendingIntent is registered
adb shell dumpsys activity intents | grep rocketnotes

# Check if deep link is registered
adb shell pm dump com.example.pensieve | grep rocketnotes
```

### App Crashes on Widget Tap
```bash
# View crash logs
adb logcat *:E

# Get stack trace
adb logcat | grep -A 50 "FATAL EXCEPTION"
```

## Useful Aliases (PowerShell)

Add to your PowerShell profile (`$PROFILE`):

```powershell
# Quick build and install
function Build-RocketApp {
    cd c:\Development\RocketNotes_AI\android-app
    flutter clean
    flutter pub get
    flutter build apk --debug
    adb install -r build\app\outputs\flutter-apk\app-debug.apk
}

# Test widgets
function Test-Widgets {
    cd c:\Development\RocketNotes_AI\android-app
    .\test-widgets.ps1
}

# Watch logs
function Watch-AppLogs {
    adb logcat | Select-String "flutter|widget|deeplink|rocket"
}

# Usage:
# Build-RocketApp
# Test-Widgets
# Watch-AppLogs
```

## Resources

- **Full Documentation**: `docs/implementation/ANDROID_WIDGETS.md`
- **Visual Guide**: `docs/WIDGET_VISUAL_GUIDE.md`
- **Summary**: `docs/implementation/WIDGET_IMPLEMENTATION_SUMMARY.md`
- **Quick Start**: `android-app/WIDGETS_README.md`

## Common Workflows

### 1. First Time Setup
```powershell
cd c:\Development\RocketNotes_AI\android-app
flutter pub get
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
# Add widgets to home screen manually
```

### 2. After Widget Code Change
```powershell
cd c:\Development\RocketNotes_AI\android-app
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
# Remove and re-add widgets to home screen
```

### 3. After Flutter Code Change (no widget change)
```powershell
cd c:\Development\RocketNotes_AI\android-app
flutter run
# Hot reload works for Flutter changes
```

### 4. Debug Widget Issues
```powershell
# 1. Check logs
adb logcat | grep -i "widget\|deeplink"

# 2. Test deep link directly
adb shell am start -W -a android.intent.action.VIEW -d "rocketnotes://camera" com.example.pensieve

# 3. Check if widget is registered
adb shell dumpsys appwidget | grep rocket

# 4. Full clean rebuild
flutter clean ; flutter pub get ; flutter build apk ; adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

---

**Quick Reference Card** - Keep this open while developing widgets! 📌
