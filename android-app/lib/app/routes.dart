// ==========================================
// lib/app/routes.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/splash_screen.dart';
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
import '../features/family/screens/family_home_screen.dart';
import '../features/family/screens/invite_member_screen.dart';
import '../features/family/screens/family_settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // EMERGENCY TEST ROUTE - FIRST PRIORITY
      GoRoute(
        path: '/emergency-test',
        builder: (context, state) {
          print('🚨 EMERGENCY TEST ROUTE LOADED! 🚨');
          return Scaffold(
            backgroundColor: Colors.yellow,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.red,
              child: const Center(
                child: Text(
                  'EMERGENCY TEST SUCCESS!!!',
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),

      // Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Home Screen
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          return const HomeScreen();
        },
      ),
      
      // Notes List Screen
      GoRoute(
        path: '/notes',
        name: 'notes',
        builder: (context, state) {
          return const NotesListScreen();
        },
      ),
      
      // Note Editor Screen
      GoRoute(
        path: '/editor',
        name: 'editor',
        builder: (context, state) {
          final noteId = state.uri.queryParameters['id'];
          final voiceNotePath = state.uri.queryParameters['voiceNotePath'];
          return NoteEditorScreen(
            noteId: noteId,
            voiceNotePath: voiceNotePath,
          );
        },
      ),
      
      // Search Screen
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return SearchScreen(initialQuery: query);
        },
      ),
      
      // Favorites Screen
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      
      // Archive Screen
      GoRoute(
        path: '/archive',
        name: 'archive',
        builder: (context, state) => const ArchiveScreen(),
      ),
      
      // Settings Screen
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Tag Management Screen
      GoRoute(
        path: '/tags',
        name: 'tags',
        builder: (context, state) => const TagManagementScreen(),
      ),
      
      // Statistics Screen
      GoRoute(
        path: '/stats',
        name: 'stats',
        builder: (context, state) => const StatisticsScreen(),
      ),
      
      // Backup Screen
      GoRoute(
        path: '/backup',
        name: 'backup',
        builder: (context, state) => const BackupScreen(),
      ),
      
      // NFC Screen
      GoRoute(
        path: '/nfc',
        name: 'nfc',
        builder: (context, state) {
          final action = state.uri.queryParameters['action']; // 'read' or 'write'
          return NfcScreen(initialAction: action);
        },
      ),

      // Test route - simplified
      GoRoute(
        path: '/test',
        builder: (context, state) {
          print('🎯 TEST ROUTE LOADED!');
          return const Scaffold(
            body: Center(
              child: Text(
                'TEST SUCCESS!',
                style: TextStyle(fontSize: 48, color: Colors.red),
              ),
            ),
          );
        },
      ),

      // Family Screens
      GoRoute(
        path: '/create-family',
        name: 'family-create',
        builder: (context, state) {
          print('🏗️ GoRouter: Building CreateFamilyScreen for path: ${state.matchedLocation}');
          return Scaffold(
            appBar: AppBar(title: const Text('Test Create Family')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('SUCCESS! Navigation Works!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Route: /create-family'),
                ],
              ),
            ),
          );
        },
      ),

      GoRoute(
        path: '/family',
        name: 'family-home',
        builder: (context, state) {
          print('🔥 MODIFIED FAMILY ROUTE LOADED! 🔥');
          return Scaffold(
            backgroundColor: Colors.green,
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.blue,
                  child: const Center(
                    child: Text(
                      'MODIFIED FAMILY ROUTE WORKS!',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Expanded(child: FamilyHomeScreen()),
              ],
            ),
          );
        },
      ),

      GoRoute(
        path: '/family/invite',
        name: 'family-invite',
        builder: (context, state) => const InviteMemberScreen(),
      ),

      GoRoute(
        path: '/family/manage-permissions',
        name: 'family-manage-permissions',
        builder: (context, state) {
          final memberJson = state.uri.queryParameters['member'];
          if (memberJson == null) {
            return const Scaffold(
              body: Center(child: Text('Member data required')),
            );
          }
          // Parsing membro da JSON implementato
          return const Scaffold(
            body: Center(child: Text('Manage Permissions - Coming Soon')),
          );
        },
      ),

      GoRoute(
        path: '/family/settings',
        name: 'family-settings',
        builder: (context, state) => const FamilySettingsScreen(),
      ),

      // Deep link handlers for NFC modes
      GoRoute(
        path: '/work',
        name: 'work-mode',
        redirect: (context, state) {
          final action = state.uri.queryParameters['action'] ?? 'home';
          return '/home?mode=work&action=$action';
        },
      ),
      
      GoRoute(
        path: '/personal',
        name: 'personal-mode',
        redirect: (context, state) {
          final action = state.uri.queryParameters['action'] ?? 'home';
          return '/home?mode=personal&action=$action';
        },
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.uri.path}" does not exist.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home),
              label: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    
    // Route redirect logic
    redirect: (context, state) {
      // Handle initial app launch
      if (state.uri.path == '/') {
        return '/'; // Show splash screen first
      }
      
      return null; // No redirect needed
    },
  );
  
  // Navigation helper methods
  static void goToNoteEditor({String? noteId, String? mode}) {
    final params = <String, String>{};
    if (noteId != null) params['id'] = noteId;
    if (mode != null) params['mode'] = mode;
    
    final uri = Uri(path: '/editor', queryParameters: params.isEmpty ? null : params);
    router.go(uri.toString());
  }
  
  static void goToNotes({String? mode, String? tag}) {
    final params = <String, String>{};
    if (mode != null) params['mode'] = mode;
    if (tag != null) params['tag'] = tag;
    
    final uri = Uri(path: '/notes', queryParameters: params.isEmpty ? null : params);
    router.go(uri.toString());
  }
  
  static void goToSearch({String? query}) {
    final params = <String, String>{};
    if (query != null) params['q'] = query;
    
    final uri = Uri(path: '/search', queryParameters: params.isEmpty ? null : params);
    router.go(uri.toString());
  }
  
  static void goToHome({String? mode, String? action}) {
    final params = <String, String>{};
    if (mode != null) params['mode'] = mode;
    if (action != null) params['action'] = action;
    
    final uri = Uri(path: '/home', queryParameters: params.isEmpty ? null : params);
    router.go(uri.toString());
  }
  
  static void goToNfc({String? action}) {
    final params = <String, String>{};
    if (action != null) params['action'] = action;
    
    final uri = Uri(path: '/nfc', queryParameters: params.isEmpty ? null : params);
    router.go(uri.toString());
  }

  static void goToFamilyHome() {
    router.go('/family');
  }

  static void goToCreateFamily() {
    print('🚀 AppRouter.goToCreateFamily() called');
    print('📍 Current location before navigation: ${router.routeInformationProvider.value.uri}');
    router.go('/create-family');
    print('✅ Navigation to /create-family executed');
  }

  static void goToInviteMember() {
    router.go('/family/invite');
  }

  static void goToManagePermissions({required String memberJson}) {
    final params = <String, String>{'member': memberJson};
    final uri = Uri(path: '/family/manage-permissions', queryParameters: params);
    router.go(uri.toString());
  }

  static void goToFamilySettings() {
    router.go('/family/settings');
  }
}
