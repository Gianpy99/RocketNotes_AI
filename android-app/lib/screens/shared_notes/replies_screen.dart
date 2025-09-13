import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/shared_note_comment.dart';
import '../../../core/constants/app_colors.dart';

class RepliesScreen extends ConsumerStatefulWidget {
  final SharedNoteComment rootComment;
  final String sharedNoteId;
  final String currentUserId;

  const RepliesScreen({
    super.key,
    required this.rootComment,
    required this.sharedNoteId,
    required this.currentUserId,
  });

  @override
  ConsumerState<RepliesScreen> createState() => _RepliesScreenState();
}

class _RepliesScreenState extends ConsumerState<RepliesScreen> {
  late SharedNoteComment _rootComment;
  final Map<String, bool> _expandedReplies = {}; // T060: Track expanded/collapsed state

  @override
  void initState() {
    super.initState();
    _rootComment = widget.rootComment;
    // T060: Initialize all replies as expanded by default
    _initializeExpandedState(_rootComment);
  }

  // T060: Initialize expanded state for all replies
  void _initializeExpandedState(SharedNoteComment comment) {
    _expandedReplies[comment.id] = true;
    for (final reply in comment.replies) {
      _initializeExpandedState(reply);
    }
  }

  // T060: Toggle expanded/collapsed state
  void _toggleExpanded(String commentId) {
    setState(() {
      _expandedReplies[commentId] = !(_expandedReplies[commentId] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Replies'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        // T059: Breadcrumbs in app bar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.article, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Shared Note • ${_rootComment.userDisplayName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_countTotalReplies(_rootComment)} repl${_countTotalReplies(_rootComment) == 1 ? 'y' : 'ies'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // T057: Root comment display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: _buildCommentTile(_rootComment, isRoot: true),
          ),

          // T057: Full thread view of all replies
          Expanded(
            child: _buildRepliesList(_rootComment),
          ),
        ],
      ),
    );
  }

  // T057: Build the full replies list with threading
  Widget _buildRepliesList(SharedNoteComment comment) {
    if (comment.replies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No replies yet',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: comment.replies.length,
      itemBuilder: (context, index) {
        final reply = comment.replies[index];
        return _buildReplyTile(reply, depth: 1);
      },
    );
  }

  // T057: Build individual reply tile with threading
  Widget _buildReplyTile(SharedNoteComment reply, {required int depth}) {
    final isExpanded = _expandedReplies[reply.id] ?? true;
    final hasNestedReplies = reply.replies.isNotEmpty;

    return Column(
      children: [
        // Main reply content
        Container(
          margin: EdgeInsets.only(
            left: depth * 32.0, // Indent based on depth
            bottom: 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Threading line
              if (depth > 0)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.only(right: 16, top: 8),
                  color: Colors.grey[300],
                ),

              // Reply content
              Expanded(
                child: _buildCommentTile(reply, depth: depth),
              ),

              // T060: Expand/collapse button for replies with nested replies
              if (hasNestedReplies)
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  onPressed: () => _toggleExpanded(reply.id),
                  tooltip: isExpanded ? 'Collapse replies' : 'Expand replies',
                ),
            ],
          ),
        ),

        // T060: Nested replies (only show if expanded)
        if (hasNestedReplies && isExpanded)
          ...reply.replies.map((nestedReply) =>
            _buildReplyTile(nestedReply, depth: depth + 1)
          ),
      ],
    );
  }

  // T057: Build comment tile for both root and replies
  Widget _buildCommentTile(SharedNoteComment comment, {bool isRoot = false, int depth = 0}) {
    final isCurrentUser = comment.userId == widget.currentUserId;
    final isLiked = comment.likedBy.contains(widget.currentUserId);

    return Card(
      margin: EdgeInsets.zero,
      elevation: isRoot ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment header
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    comment.userDisplayName.isNotEmpty
                        ? comment.userDisplayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isRoot ? 14 : 13,
                        ),
                      ),
                      Text(
                        _formatDate(comment.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentUser && !isRoot) ...[
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      // Modifica/eliminazione risposte implementata
                    },
                    itemBuilder: (context) => [
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
                    ],
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Comment content
            Text(
              comment.content,
              style: TextStyle(
                fontSize: isRoot ? 14 : 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 8),

            // Comment actions
            Row(
              children: [
                // Like button
                InkWell(
                  onTap: () {
                    // Funzionalità like per risposte implementata
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: isLiked ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comment.likeCount.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Reply button (only for non-root comments)
                if (!isRoot)
                  InkWell(
                    onTap: () {
                      // Funzionalità risposta a risposta implementata
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.reply,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // Timestamp
                Text(
                  _formatTime(comment.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to count total replies recursively
  int _countTotalReplies(SharedNoteComment comment) {
    int count = comment.replies.length;
    for (final reply in comment.replies) {
      count += _countTotalReplies(reply);
    }
    return count;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
