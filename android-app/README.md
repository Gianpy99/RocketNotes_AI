# RocketNotes AI - Flutter App

This is the main Flutter application for RocketNotes AI.

## Project Structure

```
android-app/
├── android/              # Android platform configuration
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml  # App permissions & configuration
│   │   │   └── kotlin/              # MainActivity
│   │   └── build.gradle             # App-level build configuration
│   ├── build.gradle                 # Project-level build configuration
│   ├── settings.gradle              # Gradle settings
│   └── gradle.properties            # Gradle properties
├── lib/                  # Flutter Dart source code
│   ├── main.dart        # App entry point
│   ├── app/             # App configuration and lifecycle
│   ├── core/            # Core utilities, constants, themes
│   ├── data/            # Data models, repositories, services
│   ├── domain/          # Business logic and entities
│   ├── presentation/    # State management and UI logic
│   └── ui/              # UI screens and widgets
└── pubspec.yaml         # Flutter dependencies and configuration
```

## Setup

1. Ensure Flutter SDK is installed
2. Copy `android/local.properties.template` to `android/local.properties`
3. Set your Flutter SDK path in `local.properties`:
   ```
   flutter.sdk=/path/to/flutter
   ```
4. Run `flutter pub get` to install dependencies
5. Generate Hive adapters: `flutter packages pub run build_runner build`

## Running the App

```bash
flutter run
```

## Features

- **NFC Support**: Read and write NFC tags for quick note access
- **AI Integration**: AI-powered note summaries and tag suggestions  
- **Deep Links**: Direct note access via custom URLs
- **Local Storage**: Hive-based local data persistence
- **Modern UI**: Material 3 design with dark/light themes