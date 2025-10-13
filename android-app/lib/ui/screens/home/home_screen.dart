// lib/ui/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/home/note_grid.dart';
import '../../widgets/home/quick_actions.dart';
import '../../widgets/home/stats_overview.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/floating_action_menu.dart';
import '../../widgets/voice_recording_dialog.dart';
import '../../widgets/common/family_member_selector.dart';
import '../../widgets/home/shared_notebooks_section.dart';

// Dashboard famiglia implementata
// - Add family member selector in app bar
// - Add family activity feed/timeline
// - Add shared family notes section
// - Add family reminders and tasks overview
// - Add emergency contacts quick access
// - Add family calendar integration preview

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    _refreshController.forward();
    
    try {
      await ref.read(notesProvider.notifier).loadNotes();
      await Future.delayed(const Duration(milliseconds: 500)); // Smooth UX
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        _refreshController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsyncValue = ref.watch(notesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        colors: isDarkMode 
          ? AppColors.darkGradient 
          : AppColors.lightGradient,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom App Bar with search
            CustomAppBar(
              title: 'RocketNotes AI',
              subtitle: _buildSubtitle(),
              showSearch: true,
              onSearchChanged: (query) {
                ref.read(searchQueryProvider.notifier).state = query;
              },
              actions: [
                const FamilyMemberSelector(),
                IconButton(
                  icon: AnimatedRotation(
                    turns: _isRefreshing ? 1 : 0,
                    duration: const Duration(milliseconds: 800),
                    child: const Icon(Icons.refresh_rounded),
                  ),
                  onPressed: _handleRefresh,
                  tooltip: 'Refresh',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_rounded),
                          SizedBox(width: 12),
                          Text('Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'backup',
                      child: Row(
                        children: [
                          Icon(Icons.cloud_upload_rounded),
                          SizedBox(width: 12),
                          Text('Backup'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'stats',
                      child: Row(
                        children: [
                          Icon(Icons.analytics_rounded),
                          SizedBox(width: 12),
                          Text('Statistics'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Quick Actions Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimationLimiter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 600),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        // Stats Overview
                        if (settings.value?.showStats ?? true)
                          const StatsOverview(),
                        
                        const SizedBox(height: 16),
                        
                        // Quick Actions
                        const QuickActions(),
                        
                        const SizedBox(height: 16),
                        
                        // Family Shared Notebooks
                        const SharedNotebooksSection(),
                        
                        const SizedBox(height: 24),
                        
                        // Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              searchQuery.isEmpty ? 'Recent Notes' : 'Search Results',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode 
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              ),
                            ),
                            if (searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  ref.read(searchQueryProvider.notifier).state = '';
                                },
                                child: const Text('Clear'),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Notes Grid
            notesAsyncValue.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(context, searchQuery.isNotEmpty),
                  );
                }
                return NoteGrid(notes: notes);
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => SliverFillRemaining(
                child: _buildErrorState(context, error.toString()),
              ),
            ),

            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionMenu(
        controller: _fabAnimationController,
        onNewNote: () => _navigateToNoteEditor(),
        onVoiceNote: () => _handleVoiceNote(),
      ),
    );
  }

  String _buildSubtitle() {
    final notesAsyncValue = ref.read(notesProvider);
    return notesAsyncValue.whenOrNull(
      data: (notes) {
        if (notes.isEmpty) return 'Ready to capture your ideas';
        return '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}';
      },
    ) ?? 'Loading...';
  }

  Widget _buildEmptyState(BuildContext context, bool isSearchResult) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return AnimationLimiter(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Icon(
              isSearchResult ? Icons.search_off_rounded : Icons.note_add_rounded,
              size: 80,
              color: (isDarkMode 
                ? AppColors.textSecondaryDark 
                : AppColors.textSecondaryLight).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isSearchResult 
                ? 'No notes found'
                : 'Welcome to RocketNotes AI',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode 
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearchResult
                ? 'Try adjusting your search terms'
                : 'Start capturing your thoughts and ideas',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDarkMode 
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!isSearchResult)
              FilledButton.icon(
                onPressed: _navigateToNoteEditor,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Your First Note'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode 
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode 
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: _handleRefresh,
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    // Navigate to settings or help
                    context.push('/settings');
                  },
                  child: const Text('Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        context.push('/settings');
        break;
      case 'backup':
        _showBackupDialog();
        break;
      case 'stats':
        context.push('/statistics');
        break;
    }
  }

  Future<void> _navigateToNoteEditor([String? noteId, String? voiceNotePath]) {
    final queryParams = <String, String>{};
    if (noteId != null) queryParams['id'] = noteId;
    if (voiceNotePath != null) queryParams['voiceNotePath'] = voiceNotePath;

    return context.pushNamed(
      'editor',
      queryParameters: queryParams,
    );
  }

  void _handleVoiceNote() async {
    try {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const VoiceRecordingDialog(),
      );

      if (result != null && mounted) {
        // Navigate to note editor with the voice recording
        await _navigateToNoteEditor(null, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice note failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Options'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.cloud_upload_rounded),
              title: Text('Export Backup'),
              subtitle: Text('Save notes to file'),
            ),
            ListTile(
              leading: Icon(Icons.cloud_download_rounded),
              title: Text('Import Backup'),
              subtitle: Text('Restore from file'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/backup');
            },
            child: const Text('Manage Backups'),
          ),
        ],
      ),
    );
  }
}
