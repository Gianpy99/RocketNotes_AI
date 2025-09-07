// test/widget/note_editor/note_editor_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import using correct package name
import 'package:pensieve/data/models/note_model.dart';
import 'package:pensieve/screens/note_editor_screen.dart';

void main() {
  group('NoteEditorScreen Widget Tests', () {
    Widget createTestWidget({NoteModel? note}) {
      return ProviderScope(
        child: MaterialApp(
          home: NoteEditorScreen(note: note),
        ),
      );
    }

    group('New Note Creation', () {
      testWidgets('should display new note UI elements', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for main UI elements
        expect(find.text('Nuova Nota'), findsOneWidget);
        expect(find.byType(TextField), findsAtLeastNWidgets(2));
        expect(find.byIcon(Icons.save), findsAtLeastNWidgets(1)); // Può essere presente più volte
        expect(find.text('Titolo della Nota'), findsOneWidget);
      });

      testWidgets('should allow text input in title field', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final titleField = find.byType(TextField).first;
        await tester.enterText(titleField, 'Test Title');
        expect(find.text('Test Title'), findsOneWidget);
      });

      testWidgets('should display content field', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Contenuto della Nota'), findsOneWidget);
      });
    });

    group('Mode Selection', () {
      testWidgets('should display mode selection options', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Tipo di Nota'), findsOneWidget);
        expect(find.text('Personale'), findsOneWidget);
        expect(find.text('Lavoro'), findsOneWidget);
      });
    });

    group('Image Attachments', () {
      testWidgets('should display image attachment section', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Immagini Allegate (0)'), findsOneWidget);
        expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
        expect(find.text('Nessuna immagine allegata'), findsOneWidget);
      });
    });

    group('Edit Existing Note', () {
      final testNote = NoteModel(
        id: '1',
        title: 'Existing Note',
        content: 'Existing content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['test'],
        mode: 'personal',
        attachments: [],
        isFavorite: false,
        priority: 0,
      );

      testWidgets('should display existing note data', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(note: testNote));
        await tester.pumpAndSettle();

        expect(find.text('Modifica Nota'), findsOneWidget);
        expect(find.text('Existing Note'), findsOneWidget);
        expect(find.text('Existing content'), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('should show delete confirmation dialog', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(note: testNote));
        await tester.pumpAndSettle();

        final deleteButton = find.byIcon(Icons.delete);
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Elimina Nota'), findsOneWidget);
      });
    });

    group('Tags Section', () {
      testWidgets('should display tags input field', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Tag (separati da virgola)'), findsOneWidget);
        expect(find.text('casa, lavoro, importante'), findsOneWidget);
      });
    });

    group('UI Elements', () {
      testWidgets('should display all required UI elements', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Tipo di Nota'), findsOneWidget);
        expect(find.text('Titolo della Nota'), findsOneWidget);
        expect(find.text('Contenuto della Nota'), findsOneWidget);
        expect(find.text('Tag (separati da virgola)'), findsOneWidget);
        expect(find.text('Immagini Allegate (0)'), findsOneWidget);
      });

      testWidgets('should display floating action button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('Salva Nota'), findsOneWidget);
      });
    });

    group('Rocketbook Analysis Section', () {
      final noteWithImages = NoteModel(
        id: '1',
        title: 'Note with Images',
        content: 'Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: [],
        mode: 'personal',
        attachments: ['image1.jpg'],
        isFavorite: false,
        priority: 0,
      );

      testWidgets('should show analysis section when images are present', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(note: noteWithImages));
        await tester.pumpAndSettle();

        expect(find.text('Analisi Rocketbook AI'), findsOneWidget);
        expect(find.text('Analizza Prima Immagine'), findsOneWidget);
        expect(find.text('Analizza Tutte'), findsOneWidget);
      });

      testWidgets('should not show analysis section without images', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Analisi Rocketbook AI'), findsNothing);
        expect(find.text('Analizza Prima Immagine'), findsNothing);
        expect(find.text('Analizza Tutte'), findsNothing);
      });
    });
  });
}
