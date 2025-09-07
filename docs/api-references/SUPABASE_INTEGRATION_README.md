# 🚀 RocketNotes AI - Supabase Integration

## Overview

This document outlines the implementation of Supabase integration for RocketNotes AI, enabling cross-platform synchronization, family member management, and real-time collaboration features.

## 🏗️ Architecture

### Hybrid Storage Approach
- **Local Storage**: Hive for offline-first experience
- **Cloud Storage**: Supabase for cross-platform sync
- **Real-time Sync**: Automatic synchronization when online
- **Conflict Resolution**: Last-write-wins strategy

### Data Models
- **Notes**: Core note-taking with AI summaries
- **Family Members**: Family relationship management
- **User Profiles**: Extended user information
- **Shared Notebooks**: Collaborative note sharing

## 📋 Prerequisites

### 1. Supabase Setup
1. Create a new project at [supabase.com](https://supabase.com)
2. Note your project URL and anon key
3. Run the provided SQL schema in your Supabase SQL editor

### 2. Flutter Dependencies
```yaml
dependencies:
  supabase_flutter: ^2.5.2
  connectivity_plus: ^6.1.5
```

## 🔧 Configuration

### 1. Update Supabase Config
Edit `lib/core/config/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 2. Initialize Supabase
Add to your `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NoteModelAdapter());
  Hive.registerAdapter(FamilyMemberAdapter());

  runApp(const MyApp());
}
```

## 🗄️ Database Schema

Run the `supabase-schema.sql` file in your Supabase SQL editor to create:
- User profiles table
- Notes table with family sharing support
- Family members table
- Shared notebooks table
- Row Level Security (RLS) policies
- Real-time triggers

## 🔐 Authentication

### Features
- Email/password authentication
- Automatic user profile creation
- Secure token management
- Offline authentication state

### Usage
```dart
final supabaseService = SupabaseService();

// Sign up
await supabaseService.signUp('user@example.com', 'password');

// Sign in
await supabaseService.signIn('user@example.com', 'password');

// Check auth state
final user = supabaseService.currentUser;
```

## 📱 Data Synchronization

### Hybrid Repositories
- **HybridNoteRepository**: Combines local Hive + Supabase
- **FamilyMemberRepository**: Family member management
- **Offline Support**: Full functionality without internet

### Sync Strategy
1. **Local First**: Immediate UI updates
2. **Cloud Sync**: Background synchronization
3. **Conflict Resolution**: Timestamp-based merging
4. **Error Handling**: Graceful fallback to local storage

## 👨‍👩‍👧‍👦 Family Features

### Family Member Management
```dart
final familyRepo = FamilyMemberRepository();

// Add family member
final member = FamilyMember(
  id: 'unique-id',
  name: 'John Doe',
  relationship: 'child',
  isEmergencyContact: false,
);
await familyRepo.saveFamilyMember(member);

// Get emergency contacts
final emergencyContacts = await familyRepo.getEmergencyContacts();
```

### Note Sharing
- Share notes with specific family members
- Permission-based access control
- Real-time collaboration
- Shared notebook management

## 🔄 Real-time Features

### Live Updates
```dart
// Subscribe to note changes
final subscription = supabaseService.subscribeToNotes().listen((notes) {
  // Update UI with real-time changes
});

// Subscribe to family member updates
final familySubscription = supabaseService.subscribeToFamilyMembers()
  .listen((members) {
    // Update family member list
  });
```

## 📊 Usage Examples

### Basic Note Operations
```dart
final noteRepo = HybridNoteRepository();

// Create and sync note
final note = NoteModel(
  id: 'note-id',
  title: 'My Note',
  content: 'Note content',
  mode: 'personal',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await noteRepo.saveNote(note); // Saves locally + syncs to cloud
```

### Family Collaboration
```dart
// Share note with family member
final sharedNote = note.copyWith(
  familyMemberId: 'member-id',
  isShared: true,
  sharingPermissions: ['read', 'write'],
);

await noteRepo.saveNote(sharedNote);
```

## 🔧 Development Workflow

### 1. Local Development
```bash
# Run with local Supabase (optional)
supabase start

# Update schema
supabase db push

# Generate types (if using TypeScript)
supabase gen types typescript --local > types.ts
```

### 2. Testing
```bash
# Run Flutter tests
flutter test

# Run integration tests
flutter test integration_test/
```

### 3. Deployment
```bash
# Build for production
flutter build apk --release

# Deploy Supabase functions (if any)
supabase functions deploy
```

## 🚀 Next Steps

### Phase 1: Core Sync ✅
- [x] Supabase client setup
- [x] Authentication system
- [x] Hybrid repositories
- [x] Basic note synchronization

### Phase 2: Family Features 🔄
- [ ] Family member management UI
- [ ] Note sharing interface
- [ ] Permission management
- [ ] Emergency contact integration

### Phase 3: Advanced Features 📋
- [ ] Real-time collaboration
- [ ] Conflict resolution UI
- [ ] Offline queue management
- [ ] Cross-device sync status

### Phase 4: Production Ready 🎯
- [ ] Comprehensive testing
- [ ] Performance optimization
- [ ] Security audit
- [ ] Documentation completion

## 🐛 Troubleshooting

### Common Issues

1. **Connection Issues**
   - Check Supabase URL and keys
   - Verify network connectivity
   - Check Supabase project status

2. **Sync Problems**
   - Clear local Hive boxes
   - Check RLS policies
   - Verify user authentication

3. **Performance Issues**
   - Implement pagination for large datasets
   - Optimize sync frequency
   - Use background sync

## 📚 Resources

- [Supabase Flutter Documentation](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Supabase Authentication](https://supabase.com/docs/guides/auth)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)
- [Flutter Hive Documentation](https://docs.hivedb.dev/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add tests for new functionality
5. Submit a pull request

---

**Happy coding! 🚀**
