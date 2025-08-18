// lib/core/constants/app_constants.dart
class AppConstants {
  static const String appName = 'RocketNotes AI';
  static const String appVersion = '1.0.0';
  
  // NFC URI Schemes
  static const String uriScheme = 'rocketnotes';
  static const String workMode = 'work';
  static const String personalMode = 'personal';
  
  // Storage Keys
  static const String notesBox = 'notes';
  static const String settingsBox = 'settings';
  static const String currentModeKey = 'current_mode';
  static const String themeModeKey = 'theme_mode';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
