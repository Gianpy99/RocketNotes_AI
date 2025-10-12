// Simplified routes for initial launch
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/note_editor_screen.dart';
import '../presentation/screens/notes_list_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/favorites_screen.dart';
import '../presentation/screens/archive_screen.dart';
import '../presentation/screens/search_screen.dart';
import '../presentation/screens/tag_management_screen.dart';
import '../presentation/screens/statistics_screen.dart';
import '../presentation/screens/backup_screen.dart';
import '../presentation/screens/nfc_screen.dart';
import '../../features/family/screens/family_home_screen.dart';
import '../screens/shared_notes/shared_notes_list_screen.dart';
import '../screens/shared_notes/note_sharing_screen.dart';
import '../screens/shared_notes/shared_note_viewer.dart';
import '../screens/shopping_list_screen.dart';
import '../screens/shopping_templates_screen.dart';
import '../screens/shopping_categories_screen.dart';
import '../presentation/screens/statistics_screen.dart' as stats;
import '../../features/rocketbook/camera/camera_screen.dart';
import '../screens/audio_note_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesListScreen(),
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) => const NoteEditorScreen(),
      ),
      GoRoute(
        path: '/editor/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return NoteEditorScreen(noteId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/archive',
        builder: (context, state) => const ArchiveScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return SearchScreen(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/tags',
        builder: (context, state) => const TagManagementScreen(),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/backup',
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: '/nfc',
        builder: (context, state) {
          final action = state.uri.queryParameters['action'];
          return NfcScreen(initialAction: action);
        },
      ),
      GoRoute(
        path: '/family',
        builder: (context, state) => const FamilyHomeScreen(),
      ),
      GoRoute(
        path: '/shared-notes',
        builder: (context, state) => const SharedNotesListScreen(),
      ),
      GoRoute(
        path: '/share-note',
        builder: (context, state) => const NoteSharingScreen(),
      ),
      GoRoute(
        path: '/shared-note/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return SharedNoteViewer(sharedNoteId: id!);
        },
      ),
      GoRoute(
        path: '/shopping',
        builder: (context, state) => const ShoppingListScreen(),
      ),
      GoRoute(
        path: '/shopping/templates',
        builder: (context, state) => const ShoppingTemplatesScreen(),
      ),
      GoRoute(
        path: '/shopping/categories',
        builder: (context, state) => const ShoppingCategoriesScreen(),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const stats.StatisticsScreen(),
      ),
      // Widget deep links
      GoRoute(
        path: '/camera',
        builder: (context, state) => const RocketbookCameraScreen(),
      ),
      GoRoute(
        path: '/audio',
        builder: (context, state) => const AudioNoteScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
