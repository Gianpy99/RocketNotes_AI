import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shared_note_comment.dart';

class CommentWidget extends StatelessWidget {
  final SharedNoteComment comment;
  final Function(String)? onReply;
  final Function(String)? onLike;
  final bool showReplies;
  final String? currentUserId;

  const CommentWidget({
    super.key,
    required this.comment,
    this.onReply,
    this.onLike,
    this.showReplies = true,
    this.currentUserId,
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
              ...comment.replies.map((reply) => Padding(
                padding: const EdgeInsets.only(left: 32, top: 8),
                child: CommentWidget(
                  comment: reply,
                  onReply: onReply,
                  onLike: onLike,
                  showReplies: false, // Prevent infinite nesting
                  currentUserId: currentUserId,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        // TODO: Implement edit comment
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit comment functionality coming soon!')),
        );
        break;
      case 'delete':
        // TODO: Implement delete comment
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete comment functionality coming soon!')),
        );
        break;
      case 'report':
        // TODO: Implement report comment
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
}
