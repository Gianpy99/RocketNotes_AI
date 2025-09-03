// ==========================================
// lib/main.dart (Merged Full Explicit Version)
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

Future<void> main() async {
  // Ensure Flutter bindings are initialized before async work
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ------------------------------------------
    // Initialize Hive for local storage
    // ------------------------------------------
    await Hive.initFlutter();

    // ------------------------------------------
    // Register Hive adapters
    // (these are generated with build_runner)
    // ------------------------------------------
    Hive.registerAdapter(NoteModelAdapter());
    Hive.registerAdapter(AppSettingsModelAdapter());

    // ------------------------------------------
    // Open Hive boxes
    // Use constants instead of magic strings
    // ------------------------------------------
    await Hive.openBox<NoteModel>(AppConstants.notesBox);
    await Hive.openBox<AppSettingsModel>(AppConstants.settingsBox);

    debugPrint('✅ Hive initialized successfully');
    
    // ------------------------------------------
    // Initialize AI Service
    // ------------------------------------------
    await AIService.instance.initialize();
    debugPrint('✅ AI Service initialized successfully');
  } catch (e) {
    // If Hive fails, log it but let the app continue
    // The UI should be able to handle missing storage gracefully
    debugPrint('❌ Error initializing Hive: $e');
  }

  // ------------------------------------------
  // Run the application
  // ProviderScope enables Riverpod across the app
  // ------------------------------------------
  runApp(
    const ProviderScope(
      child: RocketNotesApp(),
    ),
  );
}
