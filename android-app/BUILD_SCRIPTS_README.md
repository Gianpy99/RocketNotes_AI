# 📱 RocketNotes AI - Build Scripts

## 🚀 Universal Build Script (`build-universal.ps1`)

**Main script for all build scenarios** - Phone APK, Emulator testing, and more!

### Quick Usage

```powershell
# Build debug APK for both phone and emulator
.\build-universal.ps1

# Build release APK for phone only
.\build-universal.ps1 -BuildType release -Target phone

# Build and test on emulator
.\build-universal.ps1 -Target emulator -RunTests

# Clean build + release APK
.\build-universal.ps1 -Clean -BuildType release
```

### Full Options

```powershell
.\build-universal.ps1 [options]

OPTIONS:
  -BuildType <type>    Build type: debug (default), release, profile
  -Target <target>     Target: phone, emulator, both (default), test
  -Clean               Clean build cache before building
  -NoInstall           Build only, don't install
  -RunTests            Run integration tests after build
  -Help                Show help message
```

### Examples

```powershell
# Default: Debug build for phone + emulator
.\build-universal.ps1

# Production release
.\build-universal.ps1 -BuildType release -Target phone

# Development with emulator testing
.\build-universal.ps1 -Target emulator -RunTests

# Clean everything and build fresh
.\build-universal.ps1 -Clean -BuildType debug

# Build only (no installation)
.\build-universal.ps1 -NoInstall

# Show help
.\build-universal.ps1 -Help
```

---

## 🧪 Widget Testing (`test-widgets.ps1`)

Test the Android home screen widgets after installation.

```powershell
.\test-widgets.ps1
```

**Features:**
- Test camera widget deep link
- Test audio widget deep link
- Build and install APK option
- ADB device detection

---

## 🔥 Firebase Builds (`build-with-firebase.ps1`)

Build with Firebase environment variables from `.env` file.

```powershell
# Debug build with Firebase
.\build-with-firebase.ps1

# Release build with Firebase
.\build-with-firebase.ps1 -BuildType release
```

---

## 🔧 Other Scripts

### Icon Management
- `backup_icons.ps1` - Backup current icons
- `replace_icons.ps1` - Replace app icons
- `icon_generator.html` - Web-based icon generator

### Firebase Management
- `run-with-firebase.ps1` - Run app with Firebase config
- `rebuild-firebase.ps1` - Rebuild after Firebase changes

### Project Management
- `rebuild-after-rename.ps1` - Rebuild after package rename

---

## 📋 Prerequisites

### Required Tools
- ✅ Flutter SDK
- ✅ Android SDK (with ADB)
- ✅ PowerShell 5.1+

### Optional Tools
- 🔄 Android Studio (for emulator)
- 🔄 Android device (for testing)

### Environment Setup
```powershell
# Check Flutter
flutter --version

# Check ADB
adb version

# Check devices
adb devices
```

---

## 🎯 Common Workflows

### 1. **Daily Development**
```powershell
# Quick debug build for testing
.\build-universal.ps1
```

### 2. **Production Release**
```powershell
# Clean release build for phone
.\build-universal.ps1 -Clean -BuildType release -Target phone
```

### 3. **Emulator Testing**
```powershell
# Build and test on emulator
.\build-universal.ps1 -Target emulator -RunTests
```

### 4. **Widget Development**
```powershell
# Build and install
.\build-universal.ps1 -Target phone

# Test widgets
.\test-widgets.ps1
```

### 5. **Firebase Deployment**
```powershell
# Build with Firebase config
.\build-with-firebase.ps1 -BuildType release
```

---

## 🚨 Troubleshooting

### Build Fails
```powershell
# Clean everything
flutter clean
flutter pub cache repair
.\build-universal.ps1 -Clean
```

### ADB Issues
```powershell
# Restart ADB
adb kill-server
adb start-server

# Check devices
adb devices
```

### Emulator Issues
```powershell
# List AVDs
emulator -list-avds

# Start specific emulator
emulator -avd <avd_name>
```

### Permission Issues
```powershell
# Run as Administrator
Start-Process powershell -Verb RunAs -ArgumentList ".\build-universal.ps1"
```

---

## 📊 Build Types Explained

| Type | Use Case | Size | Speed | Debug Info |
|------|----------|------|-------|------------|
| **debug** | Development | ~400MB | Fast | Full |
| **profile** | Performance testing | ~100MB | Medium | Limited |
| **release** | Production | ~50MB | Slow | None |

---

## 🎨 Script Features

### ✅ Universal Build Script Features
- 🔄 **Multi-target**: Phone, emulator, or both
- 🧹 **Clean builds**: Optional cache cleaning
- 📦 **Auto-install**: Installs on connected devices
- 🧪 **Test integration**: Runs integration tests
- 🔥 **Firebase support**: Loads .env config
- 📊 **Progress tracking**: Colored output with status
- 🔍 **Device detection**: Auto-detects phones vs emulators
- 🛠️ **Error handling**: Comprehensive error reporting

### ✅ Widget Testing Features
- 📱 **Device scanning**: Finds connected devices
- 🔗 **Deep link testing**: Tests widget functionality
- 📦 **Build integration**: Can build APK if needed
- 🎯 **Selective testing**: Test individual widgets

---

## 📁 File Locations

```
android-app/
├── build-universal.ps1      ← Main build script ⭐
├── test-widgets.ps1         ← Widget testing
├── build-with-firebase.ps1  ← Firebase builds
├── backup_icons.ps1         ← Icon management
├── INSTALLAZIONE_APK.md     ← Installation guide
└── WIDGETS_README.md        ← Widget guide
```

---

## 🚀 Quick Start

1. **Open PowerShell** in `android-app` folder
2. **Run**: `.\build-universal.ps1`
3. **Wait** for build completion
4. **Test** on your device!

---

**Happy building! 🎉**

*Generated for RocketNotes AI - Android App*
*Date: October 2025*