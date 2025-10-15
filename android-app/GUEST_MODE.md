# Guest Mode Implementation

## Overview
Guest Mode allows users to try the app without creating an account. Guest users can create and manage notes, but with limitations on family features.

## How Guest Mode Works

### Authentication
- **Anonymous Sign-In**: When user clicks "Continue as Guest" on login screen, Firebase creates an anonymous user
- **Temporary User ID**: Each guest session gets a unique Firebase UID (e.g., `ZXKlwRscO1eDdEmdY7yQRO3CKgE3`)
- **Session-Based**: Each time user logs in as guest, a NEW anonymous UID is generated

### Guest User Capabilities

#### ✅ What Guests CAN Do:
1. **Create Notes**: Full access to note creation and editing
2. **Organize Notes**: Can use tags, favorites, work/personal modes
3. **Search & Filter**: Full search and filtering capabilities
4. **OCR & AI Features**: Access to all AI-powered features
5. **NFC Tags**: Can use NFC tag functionality
6. **Voice Notes**: Can create voice notes
7. **Quick Actions**: Access to all quick action features

#### ❌ What Guests CANNOT Do:
1. **Join/Create Family**: Family Hub is disabled for guest users
2. **Share Notes**: Cannot share notes with family members
3. **Persistent Storage**: Notes are device-local only, no cloud sync

### Data Lifecycle

#### During Guest Session:
- Notes are saved to Hive local storage with the guest's temporary userId
- Notes are visible only within that guest session
- All app features work normally (except family features)

#### After Logout:
- Guest userId changes when signing in as guest again
- Previous guest session notes remain in local storage but are hidden
- **No data is deleted** - notes stay on device with old userId

#### Privacy Isolation:
```dart
// Notes are filtered by userId
var notes = notesBox.values.where((note) {
  final hasNoUserId = note.userId == null || note.userId!.isEmpty;
  final belongsToCurrentUser = note.userId == currentUserId;
  return hasNoUserId || belongsToCurrentUser;
});
```

- User A (guest) creates notes with userId: `ABC123`
- User A logs out, User B (guest) logs in with userId: `XYZ789`
- User B CANNOT see User A's notes ✅
- Each guest session is isolated

### Legacy Notes (No UserId)
- Notes created before userId implementation have `userId=null`
- These notes are visible to ALL users (including guests)
- This maintains backward compatibility with existing data

## Implementation Details

### Router Configuration
**File**: `lib/app/routes_simple.dart`

```dart
redirect: (context, state) {
  final user = FirebaseAuth.instance.currentUser;
  final isLoginPage = state.matchedLocation == '/login';
  
  // Only redirect to login if user is completely unauthenticated
  if (user == null && !isLoginPage) {
    return '/login';
  }
  
  // Allow both authenticated and anonymous users to access app
  if (user != null && isLoginPage) {
    return '/';
  }
  
  return null;
}
```

### Family Hub Restrictions
**File**: `lib/features/family/screens/family_home_screen.dart`

Guest users see:
- 🚫 "Guest Mode" message
- ℹ️ Explanation that family features require an account
- 🔗 Button to create a real account

### Note Repository
**File**: `lib/data/repositories/note_repository.dart`

- Automatically assigns current userId (including anonymous) to new notes
- Filters notes by current userId
- Maintains backward compatibility for legacy notes

## User Experience Flow

### Guest Session Example:

1. **Start**: User clicks "Continue as Guest" on login screen
   - Firebase creates anonymous user: `ABC123`
   - Router allows access to home screen

2. **Create Notes**: User creates 3 notes
   - Note 1: "Shopping list" - userId: `ABC123`
   - Note 2: "Meeting notes" - userId: `ABC123`
   - Note 3: "Ideas" - userId: `ABC123`

3. **Try Family Hub**: User navigates to Family Hub
   - Sees "Guest Mode" message
   - Cannot create or join families
   - Prompted to create account

4. **Logout**: User logs out
   - Notes remain in local storage with userId `ABC123`
   - No data is deleted

5. **New Guest Session**: User clicks "Continue as Guest" again
   - New anonymous user: `XYZ789` (different from ABC123)
   - Sees ZERO notes (previous guest notes are hidden)
   - Can create new notes with userId `XYZ789`

6. **Create Real Account**: User decides to create account
   - Creates account with email: user@example.com, userId: `REAL456`
   - Sees legacy notes (userId=null) from before privacy implementation
   - Does NOT see guest session notes (ABC123, XYZ789)

## Upgrading Guest to Real Account

### Option 1: Manual Note Transfer (Current)
- User must manually recreate notes in real account
- Guest notes remain orphaned in local storage

### Option 2: Migration Feature (Future Enhancement)
Could implement a "Claim Guest Notes" feature:
```dart
Future<void> migrateGuestNotesToAccount(String oldGuestUserId, String newUserId) async {
  final box = Hive.box<NoteModel>(AppConstants.notesBox);
  for (var note in box.values) {
    if (note.userId == oldGuestUserId) {
      final updatedNote = note.copyWith(userId: newUserId);
      await box.put(note.id, updatedNote);
    }
  }
}
```

## Testing Scenarios

### Test Case 1: Guest Note Isolation
```
1. Login as guest (userId: ABC123)
2. Create note "Guest Note 1"
3. Verify note is visible
4. Logout
5. Login as guest again (userId: XYZ789)
6. Verify "Guest Note 1" is NOT visible ✅
7. Create note "Guest Note 2"
8. Verify only "Guest Note 2" is visible
```

### Test Case 2: Guest Cannot Access Family
```
1. Login as guest
2. Navigate to Family Hub
3. Verify "Guest Mode" message is shown
4. Verify "Create Family" button is hidden
5. Verify prompt to create account is shown
```

### Test Case 3: Legacy Notes Visibility
```
1. Ensure old notes exist with userId=null
2. Login as guest
3. Verify legacy notes (userId=null) are visible
4. Create new note
5. Verify new note has guest userId
6. Logout and login as different user
7. Verify new note is NOT visible
8. Verify legacy notes ARE still visible
```

## Files Modified

1. `lib/app/routes_simple.dart` - Allow anonymous users to access app
2. `lib/features/family/screens/family_home_screen.dart` - Add guest mode restrictions
3. `lib/data/repositories/note_repository.dart` - Filter notes by userId (already done)
4. `lib/features/auth/screens/login_screen.dart` - "Continue as Guest" button (already exists)

## Considerations

### Advantages ✅
- Low friction onboarding
- Users can try app immediately
- Privacy maintained between guest sessions
- No account required for basic features

### Limitations ⚠️
- No cloud sync for guest notes
- Notes lost when switching devices
- No way to recover notes from previous guest sessions
- Family features unavailable

### Recommendations 💡
1. Add banner in guest mode: "Create account to sync notes across devices"
2. Periodic prompt to upgrade guest account after N notes created
3. Show note count in guest mode with "Upgrade to save" CTA
4. Optional: Guest note migration when creating real account
