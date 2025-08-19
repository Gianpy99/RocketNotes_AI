// lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sync_status_widget.dart';
import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final currentMode = ref.watch(appModeProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final userId = ref.watch(userIdProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sync Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sync, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Synchronization',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Current sync status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Status'),
                        const SizedBox(height: 8),
                        const SyncStatusWidget(showText: true),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // User ID
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: const Text('User ID'),
                    subtitle: Text(
                      userId,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        // Copy user ID to clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User ID copied!')),
                        );
                      },
                    ),
                  ),
                  
                  // Manual sync button
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: syncStatus.isSyncing ? null : () {
                        ref.read(syncStatusProvider.notifier).syncNotes();
                      },
                      icon: syncStatus.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: Text(syncStatus.isSyncing ? 'Syncing...' : 'Sync Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'App Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Theme selection
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                    ),
                    title: const Text('Theme'),
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (Set<ThemeMode> selection) {
                        ref.read(themeModeProvider.notifier).setThemeMode(selection.first);
                      },
                    ),
                  ),
                  
                  // Mode selection
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      currentMode == 'work' ? Icons.work : Icons.person,
                    ),
                    title: const Text('Default Mode'),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'work',
                          label: Text('Work'),
                        ),
                        ButtonSegment(
                          value: 'personal',
                          label: Text('Personal'),
                        ),
                      ],
                      selected: {currentMode},
                      onSelectionChanged: (Set<String> selection) {
                        ref.read(appModeProvider.notifier).setMode(selection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension helper for string capitalization
extension StringCapitalization on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
