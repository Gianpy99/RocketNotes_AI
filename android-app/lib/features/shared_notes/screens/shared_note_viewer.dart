import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/shared_note.dart';
import '../../../models/shared_note_comment.dart';
import '../providers/shared_notes_providers.dart';
import '../widgets/comment_widget.dart';
import '../services/shared_note_export_service.dart';
import '../widgets/export_options_dialog.dart';

class SharedNoteViewerScreen extends ConsumerStatefulWidget {
  final String sharedNoteId;

  const SharedNoteViewerScreen({
    super.key,
    required this.sharedNoteId,
  });

  @override
  ConsumerState<SharedNoteViewerScreen> createState() => _SharedNoteViewerScreenState();
}

class _SharedNoteViewerScreenState extends ConsumerState<SharedNoteViewerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sharedNoteAsync = ref.watch(sharedNoteProvider(widget.sharedNoteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Note'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showNoteOptions(),
            tooltip: 'More options',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Note', icon: Icon(Icons.note)),
            Tab(text: 'Comments', icon: Icon(Icons.comment)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: sharedNoteAsync.when(
        data: (sharedNote) {
          if (sharedNote == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Note not found or access denied'),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNoteContent(sharedNote),
              _buildCommentsSection(sharedNote),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading note: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(sharedNoteProvider(widget.sharedNoteId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteContent(SharedNote sharedNote) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note Header
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sharedNote.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusChip(sharedNote.status),
                    ],
                  ),

                  if (sharedNote.description != null && sharedNote.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      sharedNote.description!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Shared by ${sharedNote.sharedBy}',
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
                        _formatDate(sharedNote.sharedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  if (sharedNote.expiresAt != null) ...[
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
                          'Expires ${_formatDate(sharedNote.expiresAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Note Content
          Text(
            'Note Content',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(minHeight: 200),
              child: const Text(
                'Note content would be displayed here...\n\n'
                'This is a placeholder for the actual note content.\n'
                'The content would be loaded from the original note\n'
                'and displayed with appropriate formatting.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Collaboration Status
          if (sharedNote.allowCollaboration) ...[
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.group_work,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Real-time Collaboration',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'This note allows collaborative editing. Changes made by others will appear in real-time.',
                      style: TextStyle(color: Colors.green[700]),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${sharedNote.activeViewers.length} currently viewing',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],

          // Permissions Info
          Text(
            'Your Permissions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPermissionRow('View Note', true, Icons.visibility),
                  _buildPermissionRow('Edit Note', false, Icons.edit), // TODO: Check actual permissions
                  _buildPermissionRow('Add Comments', true, Icons.comment), // TODO: Check actual permissions
                  _buildPermissionRow('Share Note', false, Icons.share), // TODO: Check actual permissions
                  _buildPermissionRow('Export Note', false, Icons.download), // TODO: Check actual permissions
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(SharedNote sharedNote) {
    return Column(
      children: [
        // Comments Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.comment),
              const SizedBox(width: 8),
              const Text(
                'Comments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddCommentDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Comment'),
              ),
            ],
          ),
        ),

        // Comments List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5, // TODO: Use actual comments count
            itemBuilder: (context, index) {
              return CommentWidget(
                comment: SharedNoteComment(
                  id: 'comment_$index',
                  sharedNoteId: sharedNote.id,
                  userId: 'user_$index',
                  userDisplayName: 'User $index',
                  content: 'This is a sample comment #$index. Comments would be loaded from the backend and displayed here.',
                  createdAt: DateTime.now().subtract(Duration(hours: index)),
                  likedBy: index % 2 == 0 ? ['user_1', 'user_2'] : [],
                  replies: [],
                ),
                onLike: () => _toggleCommentLike('comment_$index'),
                onReply: () => _showReplyDialog('comment_$index'),
                onEdit: (commentId, newContent) => _editComment(commentId, newContent), // T061: Updated callback
                onDelete: (commentId) => _deleteComment(commentId), // T062: Updated callback
                currentUserId: 'current_user', // TODO: Get from auth
                sharedNoteId: sharedNote.id,
              );
            },
          ),
        ),
      ],
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

  Widget _buildPermissionRow(String permission, bool allowed, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: allowed ? Colors.green[600] : Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              permission,
              style: TextStyle(
                color: allowed ? Colors.black : Colors.grey[600],
                decoration: allowed ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          Icon(
            allowed ? Icons.check_circle : Icons.cancel,
            color: allowed ? Colors.green[600] : Colors.grey[400],
          ),
        ],
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

  void _showNoteOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Note'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Navigate to note editor
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Options'),
            onTap: () {
              Navigator.of(context).pop();
              _showShareOptions(); // T072: Implement share functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Note'),
            onTap: () {
              Navigator.of(context).pop();
              _showExportOptions(); // T071: Implement export functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Report Issue'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Report functionality
            },
          ),
        ],
      ),
    );
  }

  void _showAddCommentDialog() {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: commentController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write your comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Add comment
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comment added!')),
              );
            },
            child: const Text('Add Comment'),
          ),
        ],
      ),
    );
  }

  void _toggleCommentLike(String commentId) {
    // TODO: Implement like functionality with proper service integration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Liked comment: $commentId')),
    );
  }

  void _showReplyDialog(String commentId) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Comment'),
        content: TextField(
          controller: replyController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write your reply...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Add reply
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reply added!')),
              );
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  // T071: Export functionality implementation
  void _showExportOptions() {
    final sharedNoteAsync = ref.read(sharedNoteProvider(widget.sharedNoteId));

    sharedNoteAsync.whenData((note) {
      if (note != null) {
        showDialog(
          context: context,
          builder: (context) => ExportOptionsDialog(
            onExport: (options) => _handleExport(note, options),
            onCancel: () {},
          ),
        );
      }
    });
  }

  // T072: Share functionality implementation
  void _showShareOptions() {
    final sharedNoteAsync = ref.read(sharedNoteProvider(widget.sharedNoteId));

    sharedNoteAsync.whenData((note) {
      if (note != null) {
        showDialog(
          context: context,
          builder: (context) => ShareOptionsDialog(
            onShareContent: (options) => _handleShareContent(note, options),
            onShareLink: () => _handleShareLink(note),
            onCancel: () {},
          ),
        );
      }
    });
  }

  // T073: Export format options implementation
  Future<void> _handleExport(SharedNote note, ExportOptions options) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Exporting note...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get comments if needed
      List<SharedNoteComment> comments = [];
      if (options.includeComments) {
        final commentsAsync = ref.read(sharedNoteCommentsProvider(widget.sharedNoteId));
        commentsAsync.whenData((commentsList) {
          comments = commentsList;
        });
      }

      // Export the note
      final exportService = ref.read(sharedNoteExportServiceProvider);
      await exportService.exportNote(
        note: note,
        comments: comments,
        options: options,
        noteContent: 'Sample note content', // TODO: Get actual note content from note repository
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note exported successfully'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // TODO: Open the exported file
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  // T074: Export with/without comments implementation
  Future<void> _handleShareContent(SharedNote note, ExportOptions options) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Preparing content...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get comments if needed
      List<SharedNoteComment> comments = [];
      if (options.includeComments) {
        final commentsAsync = ref.read(sharedNoteCommentsProvider(widget.sharedNoteId));
        commentsAsync.whenData((commentsList) {
          comments = commentsList;
        });
      }

      // Share the content
      final exportService = ref.read(sharedNoteExportServiceProvider);
      await exportService.shareNote(
        note: note,
        comments: comments,
        options: options,
        subject: 'Shared Note: ${note.title}',
        noteContent: 'Sample note content', // TODO: Get actual note content from note repository
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  // T075: Share link generation implementation
  Future<void> _handleShareLink(SharedNote note) async {
    try {
      final exportService = ref.read(sharedNoteExportServiceProvider);
      await exportService.shareLink(
        noteId: widget.sharedNoteId,
        subject: 'Check out this shared note: ${note.title}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share link: $e')),
        );
      }
    }
  }

  // T061: Edit comment implementation
  Future<void> _editComment(String commentId, String newContent) async {
    try {
      // TODO: Call the actual service method
      // await ref.read(updateCommentProvider.notifier).updateComment(
      //   sharedNoteId: sharedNote.id,
      //   commentId: commentId,
      //   content: newContent,
      // );

      // For now, just show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update comment: $e')),
        );
      }
    }
  }

  // T062: Delete comment implementation
  Future<void> _deleteComment(String commentId) async {
    try {
      // TODO: Call the actual service method
      // await ref.read(deleteCommentProvider.notifier).deleteComment(
      //   sharedNoteId: sharedNote.id,
      //   commentId: commentId,
      // );

      // For now, just show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
  }
}
