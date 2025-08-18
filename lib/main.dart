// ==========================================
// lib/main.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'data/models/note_model.dart';
import 'data/models/app_settings_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive for local storage
    await Hive.initFlutter();
    
    // Register Hive adapters
    Hive.registerAdapter(NoteModelAdapter());
    Hive.registerAdapter(AppSettingsModelAdapter());
    
    // Open Hive boxes
    await Hive.openBox<NoteModel>(AppConstants.notesBox);
    await Hive.openBox<AppSettingsModel>(AppConstants.settingsBox);
    
    print('✅ Hive initialized successfully');
  } catch (e) {
    print('❌ Error initializing Hive: $e');
    // Continue anyway - app should handle missing storage gracefully
  }
  
  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: RocketNotesApp(),
    ),
  );
}
