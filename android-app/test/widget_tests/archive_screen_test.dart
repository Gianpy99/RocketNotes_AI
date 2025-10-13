import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pensieve/presentation/screens/archive_screen.dart';
import 'package:pensieve/presentation/providers/app_providers.dart' as providers;
import 'package:pensieve/data/models/note_model.dart';
import '../mocks/mock_note_repository.dart';

void main() {
  group('ArchiveScreen', () {
    testWidgets('displays archived notes', (tester) async {
      final mockRepo = MockNoteRepository();
      mockRepo.addNote(NoteModel(
        id: '1',
        title: 'Archived Note',
        content: 'Old content',
        mode: 'personal',
        isArchived: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const ArchiveScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Archived note should appear
      expect(find.text('Archived Note'), findsOneWidget);
    });

    testWidgets('shows empty state when no archived notes', (tester) async {
      final mockRepo = MockNoteRepository();

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const ArchiveScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Empty state should appear
      expect(find.textContaining('No archived'), findsOneWidget);
    });
  });
}
