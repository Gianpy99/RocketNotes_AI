// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/nfc_service.dart';
import '../../data/services/deep_link_service.dart';
import '../../features/rocketbook/camera/camera_screen.dart';
import '../providers/app_providers_simple.dart';
import '../widgets/quick_action_button.dart';
import '../../ui/widgets/common/family_member_selector.dart';
import '../../ui/widgets/home/shared_notebooks_section.dart';
import '../../screens/audio_note_screen.dart';
import '../../data/services/widget_deep_link_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final String? initialMode;

  const HomeScreen({super.key, this.initialMode});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final NfcService _nfcService = NfcService();
  final DeepLinkService _deepLinkService = DeepLinkService();
  bool _isNfcScanning = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appModeProvider.notifier).setMode(widget.initialMode!);
      });
    }
    _listenToDeepLinks();
    _checkWidgetDeepLink();
  }

  void _checkWidgetDeepLink() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await WidgetDeepLinkService.initialize(context);
    });
  }

  void _listenToDeepLinks() {
    _deepLinkService.linkStream.listen((uri) {
      final mode = _deepLinkService.extractModeFromUri(uri);
      if (mode != null) {
        ref.read(appModeProvider.notifier).setMode(mode);
      }
    });
  }

  Future<void> _scanNfcTag() async {
    if (_isNfcScanning) return;

    setState(() {
      _isNfcScanning = true;
    });

    try {
      final result = await _nfcService.readNfcTag();
      if (result.success && result.data != null) {
        final mode = _nfcService.extractModeFromUri(result.data!);
        if (mode != null) {
          ref.read(appModeProvider.notifier).setMode(mode);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Switched to $mode mode'),
                backgroundColor: mode == 'work' 
                    ? AppColors.workBlue 
                    : AppColors.personalGreen,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading NFC tag: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isNfcScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(appModeProvider);

    return Stack(
      children: [
        Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: currentMode == 'work'
                        ? [AppColors.workBlue, AppColors.workBlue.withValues(alpha: 0.8)]
                        : [AppColors.personalGreen, AppColors.personalGreen.withValues(alpha: 0.8)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.topic_outlined),
                tooltip: 'Topics',
                onPressed: () => context.push('/topics'),
              ),
              const FamilyMemberSelector(),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Mode Toggle Button
                  InkWell(
                    onTap: () {
                      // Toggle between work and personal
                      final newMode = currentMode == 'work' ? 'personal' : 'work';
                      ref.read(appModeProvider.notifier).setMode(newMode);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: currentMode == 'work'
                            ? AppColors.workBlue.withValues(alpha: 0.1)
                            : AppColors.personalGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentMode == 'work'
                              ? AppColors.workBlue
                              : AppColors.personalGreen,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            currentMode == 'work' ? Icons.work : Icons.home,
                            color: currentMode == 'work'
                                ? AppColors.workBlue
                                : AppColors.personalGreen,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Mode',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '${currentMode.toUpperCase()} MODE',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: currentMode == 'work'
                                        ? AppColors.workBlue
                                        : AppColors.personalGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.swap_horiz,
                            color: currentMode == 'work'
                                ? AppColors.workBlue
                                : AppColors.personalGreen,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Family Shared Notebooks
                  const SharedNotebooksSection(),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.add_circle_outline,
                          label: 'New Note',
                          color: AppColors.primaryBlue,
                          onTap: () {
                            // Pass current app mode to avoid race condition
                            final currentMode = ref.read(appModeProvider);
                            context.push('/editor?mode=$currentMode');
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.list_alt,
                          label: 'All Notes',
                          color: AppColors.accentOrange,
                          onTap: () => context.push('/notes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.family_restroom,
                          label: 'Family',
                          color: AppColors.personalGreen,
                          onTap: () => context.push('/family'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.search,
                          label: 'Search',
                          color: AppColors.workBlue,
                          onTap: () => context.push('/search'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.shopping_cart,
                          label: 'Shopping',
                          color: Colors.green,
                          onTap: () => context.push('/shopping'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.bar_chart,
                          label: 'Statistics',
                          color: Colors.indigo,
                          onTap: () => context.push('/statistics'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.mic,
                          label: 'Audio Note',
                          color: Colors.deepPurple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AudioNoteScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.nfc,
                          label: 'NFC Scan',
                          color: Colors.teal,
                          onTap: _scanNfcTag,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recent Notes section removed - was not updating in real-time
                  // Users can access all notes via "All Notes" quick action
                ],
              ),
            ),
          ),
        ],
      ),
      // FLOATING ACTION BUTTON per camera
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RocketbookCameraScreen(),
            ),
          );
        },
        backgroundColor: Colors.deepPurple[700],
        tooltip: 'Open Camera',
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    ),
  ],
);
  }

}
