// ==========================================
// lib/app/app_config.dart
// ==========================================
import 'package:flutter/foundation.dart';

class AppConfig {
  // Build configuration
  static const String buildMode = kDebugMode ? 'debug' : 'release';
  static const bool isDebug = kDebugMode;
  static const bool isRelease = kReleaseMode;
  static const bool isProfile = kProfileMode;
  
  // Feature flags
  static const bool enableAI = true;
  static const bool enableNFC = true;
  static const bool enableBackup = true;
  static const bool enableDeepLinks = true;
  static const bool enableNotifications = true;
  static const bool enableAnalytics = false; // Disabled for privacy
  
  // API Configuration (for future use)
  static const String apiBaseUrl = 'https://api.rocketnotes.app';
  static const int apiTimeout = 30000; // 30 seconds
  
  // Storage Configuration
  static const int maxNotesCount = 10000;
  static const int maxNoteSize = 1024 * 1024; // 1MB
  static const int maxBackupSize = 50 * 1024 * 1024; // 50MB
  
  // UI Configuration
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration searchDebounce = Duration(milliseconds: 500);
  
  // Logging configuration
  static bool get enableLogging => isDebug;
  static bool get enableVerboseLogging => isDebug;
  
  // Performance configuration
  static const int maxConcurrentOperations = 3;
  static const Duration cacheExpiry = Duration(minutes: 30);
  
  // Security configuration
  static const bool enableBiometric = true;
  static const bool requireAppLock = false;
  static const Duration autoLockDuration = Duration(minutes: 5);
}

// Environment-specific configuration
abstract class Environment {
  static const String current = String.fromEnvironment('ENV', defaultValue: 'dev');
  static bool get isDevelopment => current == 'dev';
  static bool get isStaging => current == 'staging';
  static bool get isProduction => current == 'prod';
}

import '../data/services/deep_link_service.dart';
