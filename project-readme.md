# RocketNotes AI 🚀📝

> Transform your Rocketbook into a smart, NFC-enabled digital notebook with AI-powered insights.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📱 Overview

RocketNotes AI bridges the gap between physical note-taking and digital organization. Simply tap your phone to NFC tags on your Rocketbook to instantly categorize and digitize your notes. The app automatically recognizes whether you're in work or personal mode, keeping your notes organized and accessible.

### ✨ Key Features

- **🏷️ NFC Tag Recognition:** Instant mode switching with NTAG213 tags
- **🔗 Deep Linking:** Launch directly into work/personal contexts
- **📝 Quick Note Creation:** Capture thoughts with minimal friction
- **💾 Offline-First:** Works without internet connection
- **🤖 AI Ready:** Prepared for smart suggestions and insights (Phase 2)
- **🎨 Clean UI:** Material Design with dark mode support

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.x or higher
- Android Studio / Xcode
- Android device with NFC support (for testing)
- NTAG213 NFC tags (2 minimum)

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/yourusername/rocketnotes-ai.git
cd rocketnotes-ai
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Configure platform-specific settings:**

**Android:** Ensure minimum SDK 21 in `android/app/build.gradle`
```gradle
minSdkVersion 21
targetSdkVersion 34
```

**iOS:** Add NFC capability in Xcode project settings

4. **Run the app:**
```bash
flutter run
```

## 🏗️ Project Structure

```
rocketnotes_ai/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app/
│   │   ├── app.dart              # App configuration
│   │   └── routes.dart           # Navigation routes
│   ├── core/
│   │   ├── constants/            # App constants
│   │   ├── themes/               # Theme definitions
│   │   └── utils/                # Utility functions
│   ├── data/
│   │   ├── models/               # Data models
│   │   ├── repositories/         # Data repositories
│   │   └── services/             # External services
│   ├── domain/
│   │   ├── entities/             # Business entities
│   │   └── usecases/             # Business logic
│   └── presentation/
│       ├── screens/              # UI screens
│       ├── widgets/              # Reusable widgets
│       └── providers/            # State management
├── assets/
│   ├── images/                   # Image assets
│   └── fonts/                    # Custom fonts
├── test/                         # Unit tests
├── integration_test/             # Integration tests
└── pubspec.yaml                  # Dependencies
```

## 🏷️ NFC Setup

### Programming NFC Tags

1. **Install NFC Tools** app on your phone
2. **Write URI to tag:**
   - Work tag: `rocketnotes://work`
   - Personal tag: `rocketnotes://personal`
3. **Place tags** on your Rocketbook cover
4. **Test** by tapping phone to tags

### Supported URI Schemes

```
rocketnotes://work              # Opens app in work mode
rocketnotes://personal          # Opens app in personal mode
rocketnotes://work/new          # Creates new work note
rocketnotes://personal/view?id=xxx  # Views specific note
```

## 🛠️ Development

### Running Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test

# Coverage report
flutter test --coverage
```

### Building for Release

**Android:**
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

### Code Generation

```bash
# Generate models, routes, etc.
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📦 Dependencies

### Core Dependencies
- `flutter_nfc_kit: ^3.5.0` - NFC reading functionality
- `app_links: ^6.0.0` - Deep linking support
- `hive_flutter: ^1.1.0` - Local storage
- `riverpod: ^2.5.0` - State management
- `go_router: ^14.0.0` - Navigation

### Dev Dependencies
- `flutter_test` - Testing framework
- `flutter_lints: ^4.0.0` - Code quality
- `build_runner: ^2.4.0` - Code generation

## 🔧 Configuration

### Environment Variables

Create `.env` file in project root:
```env
# API Keys (Phase 2)
OPENAI_API_KEY=your_key_here
FIREBASE_API_KEY=your_key_here

# Feature Flags
ENABLE_AI_FEATURES=false
ENABLE_CLOUD_SYNC=false
```

### Android Manifest

The app requires these permissions:
```xml
<uses-permission android:name="android.permission.NFC" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

## 🎯 Roadmap

### ✅ MVP (Current)
- [x] NFC tag reading
- [x] Deep link handling
- [x] Mode switching UI
- [x] Basic note creation
- [x] Local storage

### 🚧 Phase 2 (In Progress)
- [ ] Camera integration
- [ ] OCR functionality
- [ ] AI suggestions
- [ ] Search feature
- [ ] Export options

### 📋 Phase 3 (Planned)
- [ ] Cloud sync
- [ ] Advanced AI features
- [ ] Calendar integration
- [ ] Collaboration tools
- [ ] Analytics dashboard

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation:** [docs.rocketnotes.ai](https://docs.rocketnotes.ai)
- **Issues:** [GitHub Issues](https://github.com/yourusername/rocketnotes-ai/issues)
- **Discord:** [Join our community](https://discord.gg/rocketnotes)
- **Email:** support@rocketnotes.ai

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Rocketbook for inspiration
- NFC Tools for tag programming
- Our amazing community of contributors

---

**Made with ❤️ by the RocketNotes AI Team**

*Remember: Your notes, your rules, your way!*