// lib/core/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseConfig {
  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'demo-api-key');
  static const String authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: 'demo-project.firebaseapp.com');
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'demo-project');
  static const String storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'demo-project.appspot.com');
  static const String messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '123456789');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:123456789:web:abcdef123456');

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: apiKey,
        authDomain: authDomain,
        projectId: projectId,
        storageBucket: storageBucket,
        messagingSenderId: messagingSenderId,
        appId: appId,
      ),
    );
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
}
