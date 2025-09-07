// ==========================================
// lib/core/constants/app_constants.dart
// ==========================================
class AppConstants {
  // App Information
  static const String appName = 'RocketNotes AI';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-powered note-taking with NFC support';
  
  // NFC URI Schemes
  static const String uriScheme = 'rocketnotes';
  static const String workMode = 'work';
  static const String personalMode = 'personal';
  
  // Deep Link URLs
  static const String workDeepLink = 'rocketnotes://work';
  static const String personalDeepLink = 'rocketnotes://personal';
  
  // Storage Keys
  static const String notesBox = 'notes';
  static const String settingsBox = 'settings';
  static const String familyMembersBox = 'family_members';
  static const String currentModeKey = 'current_mode';
  static const String themeModeKey = 'theme_mode';
  static const String lastBackupKey = 'last_backup';
  static const String userPreferencesKey = 'user_preferences';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  static const Duration splashDelay = Duration(milliseconds: 2000);
  
  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Note limits
  static const int maxNoteTitleLength = 100;
  static const int maxNoteContentLength = 10000;
  static const int maxTagsPerNote = 10;
  static const int maxTagLength = 20;
  
  // Search constants
  static const int searchDebounceMs = 300;
  static const int maxSearchResults = 100;
  
  // AI constants (for future implementation)
  static const int aiSummaryMaxLength = 200;
  static const double aiConfidenceThreshold = 0.8;
  
  // Default values
  static const String defaultMode = workMode;
  static const String defaultNoteTitle = 'Untitled Note';
  static const String defaultSearchHint = 'Search notes, tags, content...';
  
  // Error messages
  static const String errorLoadingNotes = 'Failed to load notes';
  static const String errorSavingNote = 'Failed to save note';
  static const String errorDeletingNote = 'Failed to delete note';
  static const String errorNfcNotAvailable = 'NFC not available on this device';
  static const String errorNfcRead = 'Failed to read NFC tag';
  
  // Success messages
  static const String successNoteSaved = 'Note saved successfully';
  static const String successNoteDeleted = 'Note deleted successfully';
  static const String successModeChanged = 'Mode changed successfully';
  
  // Validation patterns
  static const String tagPattern = r'^[a-zA-Z0-9_-]+$';
}
