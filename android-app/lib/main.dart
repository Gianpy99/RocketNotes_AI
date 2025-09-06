// ==========================================
// lib/main.dart - CLEANED UP MAIN ENTRY POINT
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// App imports
import 'app/app_simple.dart';
import 'core/constants/app_constants.dart';
import 'data/models/note_model.dart';
import 'data/models/app_settings_model.dart';
import 'data/models/family_member_model.dart';
import 'features/rocketbook/ai_analysis/ai_service.dart';
import 'features/rocketbook/ocr/ocr_service_real.dart';
import 'core/services/family_service.dart';

// TODO: FAMILY_FEATURES - Add family member management
// - Create FamilyMember model and Hive adapter
// - Add family member authentication/selection
// - Initialize family member data during app startup
// - Add family member switching functionality

// TODO: BACKUP_SYSTEM - Implement comprehensive backup
// - Add backup service for notes and settings
// - Implement cloud sync (Google Drive, iCloud)
// - Add automatic backup scheduling
// - Create backup/restore UI in settings

Future<void> main() async {
  // Ensure Flutter bindings are initialized before async work
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ----------------------------------
    // Initialize Hive for local storage
    // ----------------------------------
    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(NoteModelAdapter());
    Hive.registerAdapter(AppSettingsModelAdapter());

    // Register family member adapter
    Hive.registerAdapter(FamilyMemberAdapter());

    // Open Hive boxes
    await Hive.openBox<NoteModel>(AppConstants.notesBox);
    await Hive.openBox<AppSettingsModel>(AppConstants.settingsBox);

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