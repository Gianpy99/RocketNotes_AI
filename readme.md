# RocketNotes AI 🚀📝

> Transform your Rocketbook into a smart, NFC-enabled ├── backup_unused_files/         # Archived unused files (to be cleaned)
└── ARCHIVE/                     # Historical project documentation (to be cleaned)
```

## 📚 Documentation

The project now features a comprehensive, organized documentation structure:

### 📖 User Guides
- **[Complete User Guide](docs/user-guides/complete-user-guide.md)** - Full user manual with workflows and best practices
- **[Android App Guide](docs/user-guides/android-app-README.md)** - Android-specific setup and features
- **[Setup Guides](docs/user-guides/)** - Installation and configuration guides

### 🛠️ Implementation
- **[Implementation Guide](docs/implementation/complete-implementation-guide.md)** - Technical architecture and current features
- **[Future Features Roadmap](docs/implementation/future-features-roadmap.md)** - Planned enhancements based on TODO analysis
- **[API Reference](docs/api-references/complete-api-reference.md)** - Complete API documentation for all services

### 📋 Key Features Implemented
- ✅ **NFC Integration** - NTAG213 tag recognition for context switching
- ✅ **Camera & OCR** - Document scanning with Google ML Kit
- ✅ **Offline-First** - Local storage with Hive, cloud sync with Firebase
- ✅ **Rich Text Editor** - Flutter Quill integration
- ✅ **Firebase Backend** - Auth, Firestore, and Storage integration
- ✅ **Material Design 3** - Modern UI with dark mode support

### 🔮 Future Features (Based on Code TODOs)
- 👨‍👩‍👧‍👦 **Family Management** - Multi-user family accounts and sharing
- 🛒 **Advanced Shopping** - Smart shopping lists with voice input
- 🎤 **Voice Commands** - Speech-to-text and voice-controlled features
- 💾 **Backup System** - Automated cloud backups and version history
- 🔐 **Enhanced Security** - Biometric authentication and encryption
- 📋 **Clipboard Integration** - Smart copy/paste with formatting

## 🧹 Recent Cleanup (September 2025)al notebook with AI-powered insights.

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
- **🔐 Security:** End-to-end encryption and biometric authentication
- **📷 Camera Integration:** Document scanning with OCR
- **🔊 Voice Features:** Voice-to-text and voice commands (coming soon)
- **👨‍👩‍👧‍👦 Family Sharing:** Share notes with family members (coming soon)

## 🏗️ Project Structure

```
RocketNotes_AI/
├── android-app/                 # Flutter mobile application
│   ├── lib/                     # Main application code
│   ├── android/                 # Android platform code
│   ├── ios/                     # iOS platform code (future)
│   ├── test/                    # Unit and widget tests
│   └── pubspec.yaml             # Flutter dependencies
├── web-app/                     # React web application
│   ├── src/                     # Web app source code
│   ├── public/                  # Static assets
│   └── package.json             # Node.js dependencies
├── backend-api/                 # Node.js API server
│   ├── src/                     # API source code
│   └── package.json             # Server dependencies
├── docs/                        # Comprehensive documentation
│   ├── user-guides/             # User documentation
│   │   ├── complete-user-guide.md
│   │   ├── android-app-README.md
│   │   ├── backend-api-README.md
│   │   ├── web-app-README.md
│   │   └── [other guides]
│   ├── implementation/          # Technical implementation docs
│   │   ├── complete-implementation-guide.md
│   │   ├── future-features-roadmap.md
│   │   ├── AI_OCR_IMPLEMENTATION_SUMMARY.md
│   │   ├── CAMERA_FEATURES.md
│   │   ├── ROCKETBOOK_INTEGRATION_COMPLETE.md
│   │   └── SECURITY_IMPLEMENTATION.md
│   ├── api-references/          # API documentation
│   │   ├── complete-api-reference.md
│   │   ├── OPENAI_SETUP.md
│   │   ├── OPENAI_SETUP_UPDATED.md
│   │   ├── SUPABASE_INTEGRATION_README.md
│   │   └── API_SETUP.md
│   ├── development-notes/       # Development and project docs
│   │   ├── DEVELOPMENT_STATUS_ANALYSIS.md
│   │   ├── FINAL_FIXES_COMPLETE.md
│   │   ├── FIXES_IMPLEMENTED.md
│   │   └── PROJECT_DELIVERY_SUMMARY.md
│   ├── historical/              # Historical and archived docs
│   │   ├── [archived files from ARCHIVE/]
│   │   └── [files from backup_unused_files/]
│   ├── requirements/            # Product requirements
│   ├── architecture/            # System architecture docs
│   ├── changelogs/              # Development history
│   └── README.md                # Documentation index
├── shared/                      # Shared utilities and types
├── scripts/                     # Build and deployment scripts
├── ci_cd/                       # CI/CD configurations
├── docker/                      # Docker configurations
├── backup_unused_files/         # Archived unused files (to be cleaned)
└── ARCHIVE/                     # Historical project documentation (to be cleaned)
```

### 🧹 Recent Cleanup (September 2025)
- ✅ Removed empty directories (sandbox, experiments, prototypes, etc.)
- ✅ Archived unused test files and temporary backups
- ✅ Consolidated redundant documentation files
- ✅ Streamlined project structure for better maintainability

### ✅ Build Status (October 2025)
- ✅ **Flutter Android App:** Successfully builds and runs in debug mode
- ✅ **React Web App:** Successfully builds for production deployment
- ✅ **Project Structure:** Clean and optimized for development
- ✅ **Dependencies:** All required packages installed and configured
- ✅ **Java Compatibility:** Resolved obsolete Java 8 warnings

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.x or higher
- Node.js 16.x or higher
- Android Studio / Xcode
- Android device with NFC support (for testing)
- NTAG213 NFC tags (2 minimum)

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/Gianpy99/RocketNotes_AI.git
cd RocketNotes_AI
```

2. **Setup Flutter App:**
```bash
cd android-app
flutter pub get
```

3. **Setup Web App:**
```bash
cd ../web-app
npm install
```

4. **Configure platform-specific settings:**

**Android:** Ensure minimum SDK 21 in `android-app/android/app/build.gradle`
```gradle
minSdkVersion 21
targetSdkVersion 34
```

**iOS:** Add NFC capability in Xcode project settings

5. **Run the apps:**
```bash
# Flutter app
cd android-app
flutter run

# Web app (development)
cd ../web-app
npm start

# Web app (production build)
npm run build
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
├── web-app/                         # React web application
│   ├── src/                     # Web app source code
│   ├── public/                  # Static assets
│   └── package.json             # Node.js dependencies
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
cd android-app
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

**iOS:**
```bash
cd android-app
flutter build ios --release
```

**Web App:**
```bash
cd web-app
npm run build
# Build output in build/ directory
```

### Code Generation

```bash
# Generate models, routes, etc.
cd android-app
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📦 Dependencies

### Flutter App Dependencies
- `flutter_nfc_kit: ^3.5.0` - NFC reading functionality
- `app_links: ^6.0.0` - Deep linking support
- `hive_flutter: ^1.1.0` - Local storage
- `riverpod: ^2.5.0` - State management
- `go_router: ^14.0.0` - Navigation

### Web App Dependencies
- `react: ^18.2.0` - React framework
- `react-dom: ^18.2.0` - React DOM rendering
- `react-scripts: ^5.0.1` - Build and development scripts

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
- [x] **React Web App:** Basic implementation with build system

### 🚧 Current Phase: UI Implementation
- [ ] Screen implementations
- [ ] Widget components
- [ ] User interaction flows
- [ ] Testing suite development
- [ ] **Web App Features:** Enhanced UI and functionality

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
