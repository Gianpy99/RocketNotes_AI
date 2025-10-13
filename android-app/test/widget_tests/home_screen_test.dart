import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pensieve/ui/screens/home/home_screen.dart';
import 'package:pensieve/presentation/providers/app_providers.dart' as providers;
import '../mocks/mock_note_repository.dart';

void main() {
  testWidgets('HomeScreen FAB navigates to editor', (tester) async {
    // Override repository to return empty notes
    final mockRepo = MockNoteRepository();

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          name: 'editor',
          path: '/editor',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Editor Screen')),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Settings Screen')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(overrides: [
        providers.noteRepositoryProvider.overrideWithValue(mockRepo),
      ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

  // Let async notifier settle
  await tester.pumpAndSettle();

    // Tap main FAB (heroTag: "main") to navigate to editor
    final mainFab = find.byWidgetPredicate(
      (w) => w is FloatingActionButton && w.heroTag == 'main',
      description: 'Main FloatingActionButton with heroTag "main"',
    );
    expect(mainFab, findsOneWidget);
    await tester.tap(mainFab);
    await tester.pumpAndSettle();

    expect(find.text('Editor Screen'), findsOneWidget);
  });
}
