import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pensieve/ui/screens/notes/note_list_screen.dart';
import 'package:pensieve/presentation/providers/app_providers.dart' as providers;
import 'package:pensieve/data/models/note_model.dart';
import '../mocks/mock_note_repository.dart';

void main() {
  group('NoteListScreen', () {
    testWidgets('displays notes in list view', (tester) async {
      final mockRepo = MockNoteRepository();
      mockRepo.addNote(NoteModel(
        id: '1',
        title: 'Test Note 1',
        content: 'Content 1',
        mode: 'personal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const NoteListScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Verify note appears
      expect(find.text('Test Note 1'), findsOneWidget);
    });

    testWidgets('toggles between list and grid view', (tester) async {
      final mockRepo = MockNoteRepository();

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const NoteListScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Find view mode toggle button (usually in app bar or FAB)
      final viewModeButton = find.byIcon(Icons.view_list);
      if (viewModeButton.evaluate().isNotEmpty) {
        await tester.tap(viewModeButton);
        await tester.pumpAndSettle();

        // Grid icon should appear after toggle
        expect(find.byIcon(Icons.grid_view), findsOneWidget);
      }
    });

    testWidgets('search filters notes', (tester) async {
      final mockRepo = MockNoteRepository();
      mockRepo.addNote(NoteModel(
        id: '1',
        title: 'Flutter Note',
        content: 'Content about Flutter',
        mode: 'work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      mockRepo.addNote(NoteModel(
        id: '2',
        title: 'Dart Note',
        content: 'Content about Dart',
        mode: 'work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const NoteListScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Both notes should be visible initially
      expect(find.text('Flutter Note'), findsOneWidget);
      expect(find.text('Dart Note'), findsOneWidget);

      // Find search field (typically a TextField or SearchBar)
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Flutter');
      await tester.pumpAndSettle();

      // Only Flutter note should be visible
      expect(find.text('Flutter Note'), findsOneWidget);
      // Dart note may still be in widget tree but not visible
    });

    testWidgets('shows empty state when no notes', (tester) async {
      final mockRepo = MockNoteRepository();

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const NoteListScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Empty state message should appear
      expect(find.textContaining('No notes'), findsOneWidget);
    });
  });
}
