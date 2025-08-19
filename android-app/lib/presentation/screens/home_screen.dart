// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../providers/app_providers.dart';
import '../widgets/mode_selector.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_notes.dart';
import '../widgets/sync_status_widget.dart';


class HomeScreen extends ConsumerStatefulWidget {
  final String? initialMode;
  
  const HomeScreen({super.key, this.initialMode});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appModeProvider.notifier).setMode(widget.initialMode!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(appModeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ModeSelector(),
              const SizedBox(height: 24),
              const QuickActions(),
              const SizedBox(height: 24),
              Expanded(
                child: RecentNotes(mode: currentMode),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/editor'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
class HomeScreen extends ConsumerWidget {
  final String? initialMode;
  
  const HomeScreen({super.key, this.initialMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(appModeProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('RocketNotes AI'),
        actions: [
          // Sync status in app bar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: const SyncStatusWidget(showText: false),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          if (!syncStatus.isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Working offline. Changes will sync when connected.',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
          
          // Sync error banner
          if (syncStatus.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sync error: ${syncStatus.error}',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(syncStatusProvider.notifier).syncNotes();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
            
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Welcome section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🚀',
                          style: TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'RocketNotes AI',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your intelligent note-taking companion',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Sync status in welcome card
                        const SyncStatusWidget(showText: true),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Mode selection cards
                  Row(
                    children: [
                      Expanded(
                        child: _ModeCard(
                          title: 'Work Mode',
                          icon: Icons.work,
                          color: Colors.blue,
                          isSelected: currentMode == 'work',
                          onTap: () {
                            ref.read(appModeProvider.notifier).setMode('work');
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ModeCard(
                          title: 'Personal Mode',
                          icon: Icons.person,
                          color: Colors.green,
                          isSelected: currentMode == 'personal',
                          onTap: () {
                            ref.read(appModeProvider.notifier).setMode('personal');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/editor');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
