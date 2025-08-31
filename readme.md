# RocketNotes AI 🚀📝

> Transform your Rocketbook into a smart, NFC-enabled digital notebook with AI-powered insights.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Development Status](https://img.shields.io/badge/Status-Core%20Architecture%20Complete-brightgreen.svg)](docs/changelogs/DEVELOPMENT_STATUS.md)

## 📱 Overview

RocketNotes AI bridges the gap between physical note-taking and digital organization. Simply tap your phone to NFC tags on your Rocketbook to instantly categorize and digitize your notes. The app automatically recognizes whether you're in work or personal mode, keeping your notes organized and accessible.

### ✨ Key Features

- **🏷️ NFC Tag Recognition:** Instant mode switching with NTAG213 tags
- **🔗 Deep Linking:** Launch directly into work/personal contexts
- **📝 Quick Note Creation:** Capture thoughts with minimal friction
- **💾 Offline-First:** Works without internet connection
- **🤖 AI Ready:** Prepared for smart suggestions and insights (Phase 2)
- **🎨 Clean UI:** Material Design with dark mode support

## 📚 Documentation

For comprehensive documentation, please visit the **[docs/](docs/)** directory:

- **[📋 Complete Documentation Index](docs/README.md)** - Navigate all project documentation
- **[📝 Product Requirements Document](docs/requirements/PRD_ROCKETNOTES_AI.md)** - Detailed feature specifications
- **[🏗️ Setup Guide](docs/SETUP.md)** - Development environment setup
- **[📱 Development Status](docs/changelogs/DEVELOPMENT_STATUS.md)** - Current progress and roadmap
- **[📈 Changelog](docs/changelogs/CHANGELOG.md)** - Version history

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.x or higher
- Android Studio / Xcode
- Android device with NFC support (for testing)
- NTAG213 NFC tags (2 minimum)

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/Gianpy99/RocketNotes_AI.git
cd RocketNotes_AI
```

2. **Navigate to the Flutter app:**
```bash
cd android-app
```

3. **Install dependencies:**
```bash
flutter pub get
```

4. **Configure platform-specific settings:**

**Android:** Ensure minimum SDK 21 in `android-app/android/app/build.gradle`
```gradle
minSdkVersion 21
targetSdkVersion 34
```

**iOS:** Add NFC capability in Xcode project settings

5. **Run the app:**
```bash
flutter run
```

## 🏗️ Project Structure

```
RocketNotes_AI/
├── android-app/                     # Flutter mobile application
│   └── lib/
│       ├── main.dart                # App entry point
│       ├── app/                     # App configuration & routing
│       ├── core/                    # Constants, themes, utilities
│       ├── data/                    # Models, repositories, services
│       ├── domain/                  # Business entities & use cases
│       └── presentation/            # UI screens, widgets, providers
├── web-app/                         # React web application (future)
├── backend-api/                     # Node.js API server (future)
├── docs/                            # 📚 Complete documentation
│   ├── requirements/                # PRD and specifications
│   ├── architecture/                # System design documents
│   ├── changelogs/                  # Version history & status
│   └── user_guides/                 # End-user documentation
├── assets/                          # Shared assets and resources
├── configs/                         # Environment configurations
├── scripts/                         # Automation and deployment scripts
└── ARCHIVE/                         # Historical documentation
```
4. **Test** by tapping phone to tags

## 🏷️ NFC Setup

### Programming NFC Tags

1. **Install NFC Tools** app on your phone
2. **Write URI to tag:**
   - Work tag: `rocketnotes://work`
   - Personal tag: `rocketnotes://personal`
3. **Place tags** on your Rocketbook cover

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
# Navigate to Flutter app directory
cd android-app

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

Create `.env` file in `android-app/` directory:
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

## 🎯 Development Status & Roadmap

For detailed development progress, see **[Development Status](docs/changelogs/DEVELOPMENT_STATUS.md)**

### ✅ Core Architecture (Complete)
- [x] Clean architecture implementation
- [x] Data models and repositories
- [x] Service layer (NFC, AI, Search, Backup)
- [x] State management with Riverpod
- [x] App structure and routing
- [x] Local storage with Hive
- [x] Material 3 theming

### 🚧 Current Phase: UI Implementation
- [ ] Screen implementations
- [ ] Widget components
- [ ] User interaction flows
- [ ] Testing suite development

### 📋 Future Phases
- **Phase 2**: Advanced features (Camera, OCR, AI integration)
- **Phase 3**: Cloud sync and collaboration features
- **Phase 4**: Multi-platform expansion

## 🤝 Contributing

We welcome contributions! Please see our documentation for details:

- **[Contributing Guidelines](docs/CONTRIBUTING.md)** - How to contribute
- **[Architecture Overview](docs/architecture/)** - Technical architecture
- **[Setup Guide](docs/SETUP.md)** - Development environment setup

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support & Resources

- **📚 Documentation:** [Complete docs](docs/README.md)
- **🐛 Issues:** [GitHub Issues](https://github.com/Gianpy99/RocketNotes_AI/issues)
- **📧 Contact:** Open an issue for questions and support
- **📈 Status:** [Development Progress](docs/changelogs/DEVELOPMENT_STATUS.md)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Rocketbook for inspiration
- NFC Tools for tag programming reference
- Clean Architecture principles by Uncle Bob
- Material Design team for UI/UX guidelines

---

**Made with ❤️ using Flutter**

*Transform your note-taking experience with RocketNotes AI!*
