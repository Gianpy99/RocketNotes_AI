// lib/app/routes.dart
import 'package:go_router/go_router.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/note_editor_screen.dart';
import '../presentation/screens/notes_list_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/splash_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'];
          return HomeScreen(initialMode: mode);
        },
      ),
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesListScreen(),
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) {
          final noteId = state.uri.queryParameters['id'];
          return NoteEditorScreen(noteId: noteId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

