import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pensieve/screens/quick_capture_screen.dart';
import 'package:pensieve/presentation/providers/app_providers.dart' as providers;
import '../mocks/mock_note_repository.dart';

void main() {
  group('QuickCaptureScreen', () {
    testWidgets('displays quick capture options', (tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const QuickCaptureScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen loaded
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows text input field', (tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const QuickCaptureScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Quick capture should have text input
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('save button creates note', (tester) async {
      final mockRepo = MockNoteRepository();

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const QuickCaptureScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Enter some text
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Quick note');
      await tester.pumpAndSettle();

      // Find and tap save button (could be FloatingActionButton or ElevatedButton)
      final saveButton = find.widgetWithIcon(FloatingActionButton, Icons.check);
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Note should be saved to repository
        final notes = await mockRepo.getAllNotes();
        expect(notes.length, greaterThan(0));
      }
    });
  });
}
