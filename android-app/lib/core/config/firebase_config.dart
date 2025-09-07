// lib/core/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../debug/debug_logger.dart';

class FirebaseConfig {
  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const String authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '');
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const String storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
  static const String messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');

  static bool _isConfigured = false;

  static Future<void> initialize() async {
    // Check if Firebase is properly configured
    if (apiKey.isEmpty || projectId.isEmpty || appId.isEmpty) {
      DebugLogger().log('⚠️ Firebase not configured - running in offline mode only');
      _isConfigured = false;
      return;
    }

    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: apiKey,
          authDomain: authDomain,
          projectId: projectId,
          storageBucket: storageBucket,
          messagingSenderId: messagingSenderId,
          appId: appId,
        ),
      );
      _isConfigured = true;
      DebugLogger().log('✅ Firebase initialized successfully');
    } catch (e) {
      DebugLogger().log('❌ Firebase initialization failed: $e');
      DebugLogger().log('⚠️ Running in offline mode only');
      _isConfigured = false;
    }
  }

  static bool get isConfigured => _isConfigured;

  static FirebaseAuth get auth {
    if (!_isConfigured) throw Exception('Firebase not configured');
    return FirebaseAuth.instance;
  }

  static FirebaseFirestore get firestore {
    if (!_isConfigured) throw Exception('Firebase not configured');
    return FirebaseFirestore.instance;
  }

  static FirebaseStorage get storage {
    if (!_isConfigured) throw Exception('Firebase not configured');
    return FirebaseStorage.instance;
  }
}
