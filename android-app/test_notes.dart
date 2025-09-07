import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'lib/data/models/note_model.dart';
import 'lib/core/constants/app_constants.dart';

/// Script di test per aggiungere una nota di esempio al database Hive
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(NoteModelAdapter());

    // Open box
    final box = await Hive.openBox<NoteModel>(AppConstants.notesBox);

    debugPrint('📦 Box opened successfully. Current notes count: ${box.length}');

    // Create a test note
    final testNote = NoteModel(
      id: 'test_note_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Test Note',
      content: 'This is a test note created to verify the notes system is working correctly.',
      mode: 'personal',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['test', 'debug'],
      isArchived: false,
      isFavorite: false,
    );

    // Save the test note
    await box.put(testNote.id, testNote);
    debugPrint('✅ Test note saved successfully!');
    debugPrint('📝 Note ID: ${testNote.id}');
    debugPrint('📝 Note Title: ${testNote.title}');

    // Verify it was saved
    final savedNote = box.get(testNote.id);
    if (savedNote != null) {
      debugPrint('🔍 Verification successful - note found in box');
      debugPrint('📊 Total notes in box: ${box.length}');

      // List all notes
      debugPrint('\n📋 All notes in database:');
      for (var note in box.values) {
        debugPrint('  - ${note.title} (${note.mode}) - ${note.createdAt}');
      }
    } else {
      debugPrint('❌ Verification failed - note not found in box');
    }

    await box.close();
    debugPrint('\n✅ Test completed successfully!');

  } catch (e, stackTrace) {
    debugPrint('❌ Error during test: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}
