import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pensieve/ui/screens/home/home_screen.dart';
import 'package:pensieve/presentation/providers/app_providers.dart' as providers;
import 'package:pensieve/data/repositories/note_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValue;

class _DummyRepo extends NoteRepository {}

class TestErrorNotesNotifier extends providers.NotesNotifier {
  TestErrorNotesNotifier() : super(_DummyRepo());
  @override
  Future<void> loadNotes() async {
    state = AsyncValue.error(Exception('boom'), StackTrace.current);
  }
}

void main() {
  testWidgets('HomeScreen shows error state when repository throws', (tester) async {
    // Ensure enough screen space to avoid overflow in tests
    final originalSize = tester.binding.window.physicalSize;
    final originalDpr = tester.binding.window.devicePixelRatio;
    tester.binding.window.physicalSizeTestValue = const ui.Size(1080, 1920);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.physicalSizeTestValue = originalSize;
      tester.binding.window.devicePixelRatioTestValue = originalDpr;
    });
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    ]);

    await tester.pumpWidget(
      ProviderScope(overrides: [
        providers.notesProvider.overrideWith((ref) => TestErrorNotesNotifier()),
      ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // Allow any initial animations to complete
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify error UI elements (buttons present)
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
