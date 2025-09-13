import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shared_note_comment.dart';
import 'replies_screen.dart';

class CommentWidget extends StatelessWidget {
  final SharedNoteComment comment;
  final Function(String)? onReply;
  final Function(String)? onLike;
  final Function(String, String)? onEdit; // T061: Added edit callback
  final Function(String)? onDelete; // T062: Added delete callback
  final bool showReplies;
  final String? currentUserId;
  final String? sharedNoteId; // T056: Added for navigation to replies screen

  const CommentWidget({
    super.key,
    required this.comment,
    this.onReply,
    this.onLike,
    this.onEdit, // T061: Added edit callback
    this.onDelete, // T062: Added delete callback
    this.showReplies = true,
    this.currentUserId,
    this.sharedNoteId, // T056: Optional for backward compatibility
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment header
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                  child: Text(
                    comment.userDisplayName.isNotEmpty
                        ? comment.userDisplayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userDisplayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(comment.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (comment.isEdited)
                  Text(
                    'Edited',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Comment content
            Text(
              comment.content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),

            // T064: Edit indicator for edit history tracking
            if (comment.isEdited && comment.updatedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Edited ${_formatEditTime(comment.updatedAt!)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Comment actions
            Row(
              children: [
                // Like button
                TextButton.icon(
                  onPressed: onLike != null ? () => onLike!(comment.id) : null,
                  icon: Icon(
                    comment.likedBy.contains(currentUserId ?? 'current_user')
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 16,
                    color: comment.likedBy.contains(currentUserId ?? 'current_user')
                        ? Colors.red
                        : Colors.grey,
                  ),
                  label: Text(
                    '${comment.likeCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: comment.likedBy.contains(currentUserId ?? 'current_user')
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                // Reply button
                TextButton.icon(
                  onPressed: onReply != null ? () => onReply!(comment.id) : null,
                  icon: const Icon(
                    Icons.reply,
                    size: 16,
                    color: Colors.grey,
                  ),
                  label: const Text(
                    'Reply',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                const Spacer(),

                // More actions
                PopupMenuButton<String>(
                  onSelected: (action) => _handleAction(context, action),
                  itemBuilder: (context) => [
                    if (comment.userId == (currentUserId ?? 'current_user'))
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (comment.userId == (currentUserId ?? 'current_user'))
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.report, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Report', style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Colors.grey,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),

            // Replies
            if (showReplies && comment.replies.isNotEmpty) ...[
              const SizedBox(height: 8),
              // T056: Show limited replies with "View all" option
              ...comment.replies.take(2).map((reply) => Padding(
                padding: const EdgeInsets.only(left: 32, top: 8),
                child: CommentWidget(
                  comment: reply,
                  onReply: onReply,
                  onLike: onLike,
                  showReplies: false, // Prevent infinite nesting
                  currentUserId: currentUserId,
                  sharedNoteId: sharedNoteId,
                ),
              )),
              // T056: Show "View all replies" button if more than 2 replies
              if (comment.replies.length > 2) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8),
                  child: TextButton(
                    onPressed: () => _navigateToRepliesScreen(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View all ${comment.replies.length} replies',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        if (onEdit != null) {
          _showEditDialog(context); // T061: Show edit dialog
        }
        break;
      case 'delete':
        if (onDelete != null) {
          _showDeleteDialog(context); // T062: Show delete confirmation dialog
        }
        break;
      case 'report':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report functionality coming soon!')),
        );
        break;
    }
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
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  // T064: Format edit time for edit history tracking
  String _formatEditTime(DateTime editTime) {
    final now = DateTime.now();
    final difference = now.difference(editTime);

    if (difference.inDays == 0) {
      return '${editTime.hour.toString().padLeft(2, '0')}:${editTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${editTime.day}/${editTime.month}/${editTime.year}';
    }
  }

  // T056 & T058: Navigate to full replies screen
  void _navigateToRepliesScreen(BuildContext context) {
    if (sharedNoteId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RepliesScreen(
          rootComment: comment,
          sharedNoteId: sharedNoteId!,
          currentUserId: currentUserId ?? '',
        ),
      ),
    );
  }

  // T061: Show edit dialog
  void _showEditDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: comment.content);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Comment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Edit your comment...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: controller.text.trim().isEmpty || controller.text == comment.content
                          ? null
                          : () async {
                              setState(() => isLoading = true);
                              try {
                                onEdit!(comment.id, controller.text.trim());
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Comment updated successfully')),
                                  );
                                }
                              } catch (e) {
                                setState(() => isLoading = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update comment: $e')),
                                  );
                                }
                              }
                            },
                      child: const Text('Update'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // T062: Show delete confirmation dialog
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
          'Are you sure you want to delete this comment? This action can be undone within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                onDelete!(comment.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comment deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete comment: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
