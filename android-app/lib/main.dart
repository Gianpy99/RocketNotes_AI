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
import 'features/rocketbook/ai_analysis/ai_service.dart';
import 'features/rocketbook/ocr/ocr_service_real.dart';

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

    // Open Hive boxes
    await Hive.openBox<NoteModel>(AppConstants.notesBox);
    await Hive.openBox<AppSettingsModel>(AppConstants.settingsBox);

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