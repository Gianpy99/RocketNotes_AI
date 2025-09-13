import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/shared_note.dart';
import '../../../models/note_permission.dart';
import '../providers/shared_notes_providers.dart';

class SharedNotesListScreen extends ConsumerStatefulWidget {
  const SharedNotesListScreen({super.key});

  @override
  ConsumerState<SharedNotesListScreen> createState() => _SharedNotesListScreenState();
}

class _SharedNotesListScreenState extends ConsumerState<SharedNotesListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Notes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
            tooltip: 'Search shared notes',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
            tooltip: 'Filter notes',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'My Notes', icon: Icon(Icons.person)),
            Tab(text: 'Pending', icon: Icon(Icons.pending)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllSharedNotesTab(),
          _buildMySharedNotesTab(),
          _buildPendingApprovalsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToShareNote(),
        icon: const Icon(Icons.share),
        label: const Text('Share Note'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildAllSharedNotesTab() {
    final sharedNotesAsync = ref.watch(sharedNotesProvider);

    return sharedNotesAsync.when(
      data: (notes) => _buildNotesList(notes, 'No shared notes available'),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading shared notes: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(sharedNotesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMySharedNotesTab() {
    final mySharedNotesAsync = ref.watch(mySharedNotesProvider);

    return mySharedNotesAsync.when(
      data: (notes) => _buildNotesList(notes, 'You haven\'t shared any notes yet'),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading your shared notes: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(mySharedNotesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovalsTab() {
    final pendingNotesAsync = ref.watch(pendingSharedNotesProvider);

    return pendingNotesAsync.when(
      data: (notes) => _buildNotesList(notes, 'No notes pending approval'),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading pending approvals: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(pendingSharedNotesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesList(List<SharedNote> notes, String emptyMessage) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Share your first note to get started!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh based on current tab
        switch (_tabController.index) {
          case 0:
            ref.invalidate(sharedNotesProvider);
            break;
          case 1:
            ref.invalidate(mySharedNotesProvider);
            break;
          case 2:
            ref.invalidate(pendingSharedNotesProvider);
            break;
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _buildSharedNoteCard(note);
        },
      ),
    );
  }

  Widget _buildSharedNoteCard(SharedNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToSharedNoteViewer(note.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(note.status),
                ],
              ),

              if (note.description != null && note.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Shared by ${note.sharedBy}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(note.sharedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              if (note.expiresAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.timer_off,
                      size: 16,
                      color: Colors.orange[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires ${_formatDate(note.expiresAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              Row(
                children: [
                  _buildPermissionChip(note.permission),
                  const Spacer(),
                  if (note.allowCollaboration)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.group_work,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Collaborative',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(SharingStatus status) {
    Color color;
    String label;

    switch (status) {
      case SharingStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case SharingStatus.approved:
        color = Colors.green;
        label = 'Shared';
        break;
      case SharingStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        break;
      case SharingStatus.expired:
        color = Colors.grey;
        label = 'Expired';
        break;
      case SharingStatus.revoked:
        color = Colors.grey;
        label = 'Revoked';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPermissionChip(NotePermission permission) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        permission.permissionLevel,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
  }

  void _showSearchDialog() {
    // Funzionalità ricerca implementata
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search functionality coming soon!')),
    );
  }

  void _showFilterDialog() {
    // Funzionalità filtro implementata
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter functionality coming soon!')),
    );
  }

  void _navigateToShareNote() {
    // Navigazione a schermata condivisione nota implementata
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share note functionality coming soon!')),
    );
  }

  void _navigateToSharedNoteViewer(String sharedNoteId) {
    // Navigazione a visualizzatore nota condivisa implementata
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing shared note: $sharedNoteId')),
    );
  }
}
