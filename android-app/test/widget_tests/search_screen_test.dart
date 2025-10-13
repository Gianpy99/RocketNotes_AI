import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pensieve/presentation/screens/search_screen.dart';
import 'package:pensieve/presentation/providers/app_providers.dart' as providers;
import 'package:pensieve/data/models/note_model.dart';
import '../mocks/mock_note_repository.dart';

void main() {
  group('SearchScreen', () {
    testWidgets('displays search field', (tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const SearchScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Search screen should have a search field
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('search returns matching notes', (tester) async {
      final mockRepo = MockNoteRepository();
      mockRepo.addNote(NoteModel(
        id: '1',
        title: 'Flutter Development',
        content: 'Content about Flutter',
        mode: 'work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      mockRepo.addNote(NoteModel(
        id: '2',
        title: 'Shopping List',
        content: 'Buy groceries',
        mode: 'personal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const SearchScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Flutter');
      await tester.pumpAndSettle();

      // Should find Flutter note
      expect(find.text('Flutter Development'), findsOneWidget);
    });

    testWidgets('shows empty state for no results', (tester) async {
      final mockRepo = MockNoteRepository();

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const SearchScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Search for non-existent content
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'NonExistentQuery123');
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.textContaining('No results'), findsOneWidget);
    });
  });
}
