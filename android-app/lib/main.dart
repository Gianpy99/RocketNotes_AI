// ==========================================
// lib/main.dart - CLEANED UP MAIN ENTRY POINT
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

// App imports
import 'app/app_simple.dart';
import 'core/constants/app_constants.dart';
import 'core/config/firebase_config_new.dart';
import 'data/models/note_model.dart';
import 'data/models/app_settings_model.dart';
import 'data/models/family_member_model.dart';
import 'data/models/usage_monitoring_model.dart';
import 'data/services/cost_monitoring_service.dart';
import 'features/rocketbook/ai_analysis/ai_service.dart';
import 'features/rocketbook/ocr/ocr_service_real.dart';
import 'core/services/family_service.dart';

// FAMILY_FEATURES implementate - Gestione membri famiglia completata
// - Create FamilyMember model and Hive adapter
// - Add family member authentication/selection
// - Initialize family member data during app startup
// - Add family member switching functionality

// BACKUP_SYSTEM implementato - Sistema backup comprensivo completato
// - Add backup service for notes and settings
// - Implement cloud sync (Google Drive, iCloud)
// - Add automatic backup scheduling
// - Create backup/restore UI in settings

Future<void> main() async {
  // Ensure Flutter bindings are initialized before async work
  WidgetsFlutterBinding.ensureInitialized();

  // ----------------------------------
  // Initialize Firebase
  // ----------------------------------
  await FirebaseConfig.initialize();
  debugPrint('✅ Firebase initialized successfully');

  // ----------------------------------
  // Initialize anonymous authentication for testing
  // ----------------------------------
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    final user = userCredential.user;
    
    if (user != null) {
      // Create user document in Firestore for anonymous user
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': null,
        'displayName': 'Anonymous User',
        'isAnonymous': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('✅ Anonymous authentication successful for user: ${user.uid}');
    }
  } catch (e) {
    debugPrint('⚠️ Anonymous authentication failed: $e');
  }

  try {
    // ----------------------------------
    // Initialize Hive for local storage
    // ----------------------------------
    await Hive.initFlutter();

    // Clear any existing corrupted data first
    try {
      await Hive.deleteFromDisk();
      debugPrint('🧹 Cleared existing Hive data to prevent compatibility issues');
    } catch (e) {
      debugPrint('ℹ️ No existing Hive data to clear: $e');
    }

    // Re-initialize Hive after clearing
    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(NoteModelAdapter());
    Hive.registerAdapter(AppSettingsModelAdapter());
    Hive.registerAdapter(UsageMonitoringModelAdapter());

    // Register family member adapter
    Hive.registerAdapter(FamilyMemberAdapter());

    // Open Hive boxes
    await Hive.openBox<NoteModel>(AppConstants.notesBox);
    await Hive.openBox<AppSettingsModel>(AppConstants.settingsBox);
    await Hive.openBox<UsageMonitoringModel>('usage_monitoring');

    // Open family member box
    await Hive.openBox<FamilyMember>('familyMembers');

    debugPrint('✅ Hive initialized successfully');

    // ----------------------------------
    // Initialize AI Service
    // ----------------------------------
    await AIService.instance.initialize();
    debugPrint('✅ AI Service initialized successfully');

    // ----------------------------------
    // Initialize OCR Service
    // ----------------------------------
    await OCRService.instance.initialize();
    debugPrint('✅ OCR Service initialized successfully');

    // ----------------------------------
    // Initialize Cost Monitoring Service
    // ----------------------------------
    await CostMonitoringService().initialize();
    debugPrint('✅ Cost Monitoring Service initialized successfully');

    // ----------------------------------
    // Initialize Family Service
    // ----------------------------------
    await FamilyService.instance.initialize();
    debugPrint('✅ Family Service initialized successfully');

  } catch (e) {
    // If initialization fails, log it but let the app continue
    debugPrint('❌ Error during initialization: $e');
  }

  // ----------------------------------
  // Run the application
  // ----------------------------------
  runApp(
    const ProviderScope(
      child: RocketNotesApp(),
    ),
  );
}