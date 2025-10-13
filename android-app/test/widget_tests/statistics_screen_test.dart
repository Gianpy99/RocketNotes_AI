import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pensieve/presentation/screens/statistics_screen.dart';
import 'package:pensieve/presentation/providers/app_providers.dart' as providers;
import 'package:pensieve/data/models/note_model.dart';
import '../mocks/mock_note_repository.dart';

void main() {
  group('StatisticsScreen', () {
    testWidgets('displays statistics when notes exist', (tester) async {
      final mockRepo = MockNoteRepository();
      mockRepo.addNote(NoteModel(
        id: '1',
        title: 'Note 1',
        content: 'Content',
        mode: 'work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      mockRepo.addNote(NoteModel(
        id: '2',
        title: 'Note 2',
        content: 'Content',
        mode: 'personal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const StatisticsScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Statistics should display
      expect(find.byType(Scaffold), findsOneWidget);
      // Should show some statistics text
      expect(find.textContaining('Total'), findsAny);
    });

    testWidgets('shows empty state when no notes', (tester) async {
      final mockRepo = MockNoteRepository();

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const StatisticsScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty or zero stats
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
