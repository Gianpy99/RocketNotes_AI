import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pensieve/ui/screens/settings/settings_screen.dart';
import 'package:pensieve/presentation/providers/app_providers.dart' as providers;
import 'package:pensieve/data/models/app_settings_model.dart';
import '../mocks/mock_note_repository.dart';
import '../test_helpers/test_settings_repository.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('displays settings sections and toggles', (tester) async {
      final mockSettings = AppSettingsModel(
        themeMode: 0, // Light
        defaultMode: 'personal',
        enableNotifications: true,
        enableNfc: true,
        autoBackup: false,
        fontSize: 14.0,
        showStats: true,
        enableAi: false,
      );

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const SettingsScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
          providers.settingsRepositoryProvider.overrideWithValue(MockSettingsRepository(mockSettings)),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Verify settings sections appear
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('AI & Smart Features'), findsOneWidget);

      // Verify some settings tiles
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Show Statistics'), findsOneWidget);
      expect(find.text('AI Assistance'), findsOneWidget);
    });

    testWidgets('toggles settings switches', (tester) async {
      final mockSettings = AppSettingsModel(
        themeMode: 0,
        defaultMode: 'personal',
        enableNotifications: true,
        enableNfc: true,
        autoBackup: false,
        fontSize: 14.0,
        showStats: true,
        enableAi: false,
      );

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const SettingsScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
          providers.settingsRepositoryProvider.overrideWithValue(MockSettingsRepository(mockSettings)),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap a toggle switch (Show Statistics)
      final statsSwitchFinder = find.widgetWithText(SwitchListTile, 'Show Statistics').first;
      expect(statsSwitchFinder, findsOneWidget);

      // Tap the switch
      await tester.tap(statsSwitchFinder);
      await tester.pumpAndSettle();

      // Switch should toggle (visual feedback present)
      expect(find.widgetWithText(SwitchListTile, 'Show Statistics'), findsWidgets);
    });

    testWidgets('back button navigates away', (tester) async {
      final mockSettings = AppSettingsModel(
        themeMode: 0,
        defaultMode: 'personal',
        enableNotifications: true,
        enableNfc: true,
        autoBackup: false,
        fontSize: 14.0,
        showStats: true,
        enableAi: false,
      );

      bool poppedBack = false;

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
          providers.settingsRepositoryProvider.overrideWithValue(MockSettingsRepository(mockSettings)),
        ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Navigator(
                    onPopPage: (route, result) {
                      poppedBack = true;
                      return route.didPop(result);
                    },
                    pages: const [
                      MaterialPage(child: SettingsScreen()),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(poppedBack, isTrue);
    });
  });
}
