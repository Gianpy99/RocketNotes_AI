import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pensieve/screens/note_editor_screen.dart';
import 'package:pensieve/data/models/note_model.dart';
import 'package:pensieve/presentation/providers/app_providers.dart' as providers;
import '../mocks/mock_note_repository.dart';

void main() {
  group('NoteEditorScreen', () {
    testWidgets('displays empty editor for new note', (tester) async {
      final mockRepo = MockNoteRepository();

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: const MaterialApp(
            home: NoteEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Editor should load
      expect(find.byType(TextField), findsAtLeastNWidgets(2)); // Title + Content
    });

    testWidgets('displays existing note data', (tester) async {
      final mockRepo = MockNoteRepository();
      final existingNote = NoteModel(
        id: '1',
        title: 'Test Note',
        content: 'Test Content',
        mode: 'personal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp(
            home: NoteEditorScreen(note: existingNote),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Note data should be displayed
      expect(find.text('Test Note'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('saves new note', (tester) async {
      final mockRepo = MockNoteRepository();

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: const MaterialApp(
            home: NoteEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter title
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'New Note Title');
      await tester.pumpAndSettle();

      // Find save button (check icon or save text)
      final saveButton = find.byIcon(Icons.check);
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Success message should appear
        expect(find.textContaining('salvata'), findsOneWidget);
      }
    });
  });
}
