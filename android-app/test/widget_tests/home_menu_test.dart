import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pensieve/ui/screens/home/home_screen.dart';
import 'package:pensieve/presentation/providers/app_providers.dart' as providers;
import '../mocks/mock_note_repository.dart';

void main() {
  group('HomeScreen menu actions', () {
    testWidgets('navigates to Settings from overflow menu', (tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const Scaffold(body: Center(child: Text('Settings Screen')))),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Open overflow menu
      final menuButton = find.byType(PopupMenuButton<String>);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Tap Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('shows Backup dialog from overflow menu', (tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Open overflow menu
      final menuButton = find.byType(PopupMenuButton<String>);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Tap Backup
      await tester.tap(find.text('Backup'));
      await tester.pumpAndSettle();

      // Expect backup dialog
      expect(find.text('Backup Options'), findsOneWidget);
      expect(find.text('Manage Backups'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Backup Options'), findsNothing);
    });
  });
}
