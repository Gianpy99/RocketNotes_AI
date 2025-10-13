// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/note_model.dart';
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
    final recentWorkNotes = ref.watch(recentWorkNotesProvider(7)); // Get work notes from last 7 days
    final recentPersonalNotes = ref.watch(recentPersonalNotesProvider(7)); // Get personal notes from last 7 days

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

                  // Recent Notes - Show based on current mode
                  currentMode == 'work' 
                    ? _buildRecentNotesSection(context, recentWorkNotes, 'Recent Work Notes')
                    : _buildRecentNotesSection(context, recentPersonalNotes, 'Recent Personal Notes'),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildRecentNotesSection(BuildContext context, AsyncValue<List<NoteModel>> notesAsync, String title) {
    return notesAsync.when(
      data: (notes) {
        if (notes.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...notes.take(3).map((note) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: note.mode == 'work'
                            ? AppColors.workBlue
                            : AppColors.personalGreen,
                        child: Icon(
                          note.mode == 'work' ? Icons.work : Icons.home,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        note.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatDate(note.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () => context.push('/editor?id=${note.id}'),
                    ),
                  )),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 48,
                      color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first note to get started',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

}