// lib/core/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';

/// Firebase Configuration
/// This file configures Firebase using the centralized ApiConfig.
class FirebaseConfig {
  static FirebaseOptions get currentPlatform {
    if (ApiConfig.hasFirebaseConfig) {
      return FirebaseOptions(
        apiKey: ApiConfig.actualFirebaseApiKey,
        appId: ApiConfig.actualFirebaseAppId,
        messagingSenderId: ApiConfig.actualFirebaseMessagingSenderId,
        projectId: ApiConfig.actualFirebaseProjectId,
        authDomain: '${ApiConfig.actualFirebaseProjectId}.firebaseapp.com',
        storageBucket: '${ApiConfig.actualFirebaseProjectId}.appspot.com',
      );
    }
    
    throw Exception('Firebase not configured! Update keys in api_config.dart');
  }
  
  static Future<void> initialize() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ Firebase already initialized, skipping...');
          debugPrint('📊 Config status: ${ApiConfig.configStatus}');
        }
        return;
      }
      
      await Firebase.initializeApp(options: currentPlatform);
      if (kDebugMode) {
        debugPrint('✅ Firebase initialized successfully');
        debugPrint('📊 Config status: ${ApiConfig.configStatus}');
      }
    } catch (e) {
      // Handle duplicate app error specifically
      if (e.toString().contains('duplicate-app') || e.toString().contains('[DEFAULT]')) {
        if (kDebugMode) {
          debugPrint('✅ Firebase app already exists, continuing...');
          debugPrint('📊 Config status: ${ApiConfig.configStatus}');
        }
        return;
      }
      if (kDebugMode) {
        debugPrint('❌ Firebase initialization failed: $e');
      }
      rethrow;
    }
  }
  
  static bool get isConfigured => ApiConfig.hasFirebaseConfig;
  
  static Map<String, dynamic> get debugInfo => {
    'is_configured': isConfigured,
    'project_id': ApiConfig.actualFirebaseProjectId,
    'has_messaging': ApiConfig.hasFirebaseMessaging,
    'config_source': 'api_config',
  };
}