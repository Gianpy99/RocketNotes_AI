// test/widget/note_editor/note_editor_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rocketnotes_ai/data/models/note.dart';
import 'package:rocketnotes_ai/data/repositories/note_repository.dart';
import 'package:rocketnotes_ai/data/repositories/settings_repository.dart';
import 'package:rocketnotes_ai/ui/screens/note_editor/note_editor_screen_complete.dart';
import 'package:rocketnotes_ai/providers/app_providers.dart';

import 'note_editor_screen_test.mocks.dart';

@GenerateMocks([NoteRepository, SettingsRepository])
void main() {
  group('NoteEditorScreen Widget Tests', () {
    late MockNoteRepository mockNoteRepository;
    late MockSettingsRepository mockSettingsRepository;

    setUp(() {
      mockNoteRepository = MockNoteRepository();
      mockSettingsRepository = MockSettingsRepository();
    });

    Widget createTestWidget({String? noteId, Map<String, dynamic>? initialData}) {
      return ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(mockNoteRepository),
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepository),
        ],
        child: MaterialApp(
          home: NoteEditorScreen(
            noteId: noteId,
            initialData: initialData,
          ),
        ),
      );
    }

    group('New Note Creation', () {
      testWidgets('should display new note UI elements', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for main UI elements
        expect(find.text('New Note'), findsOneWidget);
        expect(find.byType(TextField), findsAtLeastNWidgets(2)); // Title and tag input
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Note title...'), findsOneWidget);
      });

      testWidgets('should allow entering title and content', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find title input field
        final titleField = find.widgetWithText(TextField, 'Note title...');
        expect(titleField, findsOneWidget);

        // Enter title
        await tester.enterText(titleField, 'Test Note Title');
        await tester.pump();

        // Verify title was entered
        expect(find.text('Test Note Title'), findsOneWidget);
      });

      testWidgets('should show unsaved changes indicator', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter some text to trigger unsaved changes
        final titleField = find.widgetWithText(TextField, 'Note title...');
        await tester.enterText(titleField, 'Test');
        await tester.pump();

        // Should show unsaved changes indicator
        expect(find.text('Unsaved changes'), findsOneWidget);
      });
    });

    group('Existing Note Editing', () {
      final testNote = Note(
        id: 'test-note-id',
        title: 'Existing Note Title',
        content: 'Existing note content',
        tags: ['test', 'existing'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      testWidgets('should load and display existing note', (WidgetTester tester) async {
        // Mock repository response
        when(mockNoteRepository.getNoteById('test-note-id'))
            .thenAnswer((_) async => testNote);

        await tester.pumpWidget(createTestWidget(noteId: 'test-note-id'));
        await tester.pumpAndSettle();

        // Check that existing note data is loaded
        expect(find.text('Edit Note'), findsOneWidget);
        expect(find.text('Existing Note Title'), findsOneWidget);
        
        // Check for tags
        expect(find.text('test'), findsOneWidget);
        expect(find.text('existing'), findsOneWidget);
      });

      testWidgets('should show delete button for existing notes', (WidgetTester tester) async {
        when(mockNoteRepository.getNoteById('test-note-id'))
            .thenAnswer((_) async => testNote);

        await tester.pumpWidget(createTestWidget(noteId: 'test-note-id'));
        await tester.pumpAndSettle();

        // Should show delete button
        expect(find.byIcon(Icons.delete_rounded), findsOneWidget);
      });
    });

    group('Save Functionality', () {
      testWidgets('should save new note when save button pressed', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter note data
        final titleField = find.widgetWithText(TextField, 'Note title...');
        await tester.enterText(titleField, 'New Note');
        await tester.pump();

        // Mock successful save
        when(mockNoteRepository.createNote(any))
            .thenAnswer((_) async => {});

        // Tap save button
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Verify createNote was called
        verify(mockNoteRepository.createNote(any)).called(1);
      });

      testWidgets('should show saving indicator when saving', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter note data
        final titleField = find.widgetWithText(TextField, 'Note title...');
        await tester.enterText(titleField, 'New Note');
        await tester.pump();

        // Mock delayed save
        when(mockNoteRepository.createNote(any))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 1));
        });

        // Tap save button
        await tester.tap(find.text('Save'));
        await tester.pump(); // Don't settle yet

        // Should show saving indicator
        expect(find.text('Saving...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Tag Management', () {
      testWidgets('should allow adding tags', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find tag input field
        final tagField = find.widgetWithText(TextField, 'Add tags...');
        expect(tagField, findsOneWidget);

        // Enter tag
        await tester.enterText(tagField, 'test-tag');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        // Should show the tag chip
        expect(find.text('test-tag'), findsOneWidget);
        expect(find.byType(Chip), findsOneWidget);
      });

      testWidgets('should allow removing tags', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Add a tag first
        final tagField = find.widgetWithText(TextField, 'Add tags...');
        await tester.enterText(tagField, 'removable-tag');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        // Should show the tag chip
        expect(find.text('removable-tag'), findsOneWidget);

        // Find and tap the delete button on the chip
        final deleteButton = find.descendant(
          of: find.byType(Chip),
          matching: find.byIcon(Icons.close),
        );
        expect(deleteButton, findsOneWidget);

        await tester.tap(deleteButton);
        await tester.pump();

        // Tag should be removed
        expect(find.text('removable-tag'), findsNothing);
      });
    });

    group('Navigation', () {
      testWidgets('should show back button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      });

      testWidgets('should show unsaved changes dialog when navigating back', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Make changes to trigger unsaved state
        final titleField = find.widgetWithText(TextField, 'Note title...');
        await tester.enterText(titleField, 'Unsaved changes');
        await tester.pump();

        // Try to go back
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();

        // Should show confirmation dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Unsaved Changes'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should show error when save fails', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter note data
        final titleField = find.widgetWithText(TextField, 'Note title...');
        await tester.enterText(titleField, 'Error Note');
        await tester.pump();

        // Mock save failure
        when(mockNoteRepository.createNote(any))
            .thenThrow(Exception('Save failed'));

        // Tap save button
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should show error snackbar
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Failed to save note'), findsOneWidget);
      });

      testWidgets('should show error when loading note fails', (WidgetTester tester) async {
        // Mock load failure
        when(mockNoteRepository.getNoteById('failing-id'))
            .thenThrow(Exception('Load failed'));

        await tester.pumpWidget(createTestWidget(noteId: 'failing-id'));
        await tester.pumpAndSettle();

        // Should show error snackbar
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Failed to load note'), findsOneWidget);
      });
    });

    group('AI Features', () {
      testWidgets('should show AI suggestions when content is entered', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter enough content to trigger AI suggestions
        final titleField = find.widgetWithText(TextField, 'Note title...');
        await tester.enterText(titleField, 'This is a long note that should trigger AI suggestions because it has enough content');
        await tester.pump();

        // Should show AI suggestions widget
        expect(find.text('AI Writing Assistant'), findsOneWidget);
      });

      testWidgets('should show smart tag suggestions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter content that should trigger tag suggestions
        final titleField = find.widgetWithText(TextField, 'Note title...');
        await tester.enterText(titleField, 'Meeting notes from today about project planning');
        await tester.pump();

        // Should show smart tag suggestions
        expect(find.text('Smart Tag Suggestions'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for important accessibility elements
        expect(find.byTooltip('Back'), findsOneWidget);
        expect(find.byTooltip('Share'), findsAny);
        expect(find.byTooltip('Delete'), findsAny);
      });
    });
  });
}
