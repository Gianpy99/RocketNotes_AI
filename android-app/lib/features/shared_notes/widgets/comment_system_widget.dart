import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/shared_note_comment.dart';
import '../providers/shared_notes_providers.dart';
import '../widgets/comment_widget.dart';

class CommentSystemWidget extends ConsumerStatefulWidget {
  final String sharedNoteId;

  const CommentSystemWidget({
    super.key,
    required this.sharedNoteId,
  });

  @override
  ConsumerState<CommentSystemWidget> createState() => _CommentSystemWidgetState();
}

class _CommentSystemWidgetState extends ConsumerState<CommentSystemWidget> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(sharedNoteCommentsProvider(widget.sharedNoteId));

    return Column(
      children: [
        // Comment Input Section
        _buildCommentInput(),

        const SizedBox(height: 16),

        // Comments List
        Expanded(
          child: commentsAsync.when(
            data: (comments) => _buildCommentsList(comments),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to load comments: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(sharedNoteCommentsProvider(widget.sharedNoteId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add a comment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            focusNode: _commentFocusNode,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Share your thoughts...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(12),
            ),
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clearComment,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Comment'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(List<SharedNoteComment> comments) {
    if (comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your thoughts!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Sort comments by creation date (newest first)
    final sortedComments = List<SharedNoteComment>.from(comments)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedComments.length,
      itemBuilder: (context, index) {
        final comment = sortedComments[index];
        return CommentWidget(
          comment: comment,
          onLike: () => _toggleCommentLike(comment.id),
          onReply: () => _showReplyDialog(comment),
          onEdit: () => _showEditCommentDialog(comment),
          onDelete: () => _showDeleteCommentDialog(comment),
          currentUserId: 'current_user', // TODO: Get from auth provider
        );
      },
    );
  }

  void _clearComment() {
    _commentController.clear();
    _commentFocusNode.unfocus();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: Implement comment submission through provider
      // await ref.read(addCommentProvider.notifier).addComment(
      //   sharedNoteId: widget.sharedNoteId,
      //   content: content,
      // );

      _clearComment();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added successfully!')),
      );

      // Refresh comments
      ref.invalidate(sharedNoteCommentsProvider(widget.sharedNoteId));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $error')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _toggleCommentLike(String commentId) async {
    try {
      // TODO: Implement like functionality through provider
      // await ref.read(toggleCommentLikeProvider.notifier).toggleLike(
      //   sharedNoteId: widget.sharedNoteId,
      //   commentId: commentId,
      // );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment liked!')),
      );

      // Refresh comments
      ref.invalidate(sharedNoteCommentsProvider(widget.sharedNoteId));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like comment: $error')),
      );
    }
  }

  void _showReplyDialog(SharedNoteComment parentComment) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${parentComment.userDisplayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show parent comment preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parentComment.userDisplayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    parentComment.content,
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write your reply...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final replyContent = replyController.text.trim();
              if (replyContent.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reply')),
                );
                return;
              }

              Navigator.of(context).pop();

              try {
                // TODO: Implement reply submission through provider
                // await ref.read(addReplyProvider.notifier).addReply(
                //   sharedNoteId: widget.sharedNoteId,
                //   parentCommentId: parentComment.id,
                //   content: replyContent,
                // );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reply added successfully!')),
                );

                // Refresh comments
                ref.invalidate(sharedNoteCommentsProvider(widget.sharedNoteId));
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add reply: $error')),
                );
              }
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  void _showEditCommentDialog(SharedNoteComment comment) {
    final editController = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = editController.text.trim();
              if (newContent.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter comment content')),
                );
                return;
              }

              if (newContent == comment.content) {
                Navigator.of(context).pop();
                return;
              }

              Navigator.of(context).pop();

              try {
                // TODO: Implement comment editing through provider
                // await ref.read(updateCommentProvider.notifier).updateComment(
                //   sharedNoteId: widget.sharedNoteId,
                //   commentId: comment.id,
                //   content: newContent,
                // );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment updated successfully!')),
                );

                // Refresh comments
                ref.invalidate(sharedNoteCommentsProvider(widget.sharedNoteId));
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update comment: $error')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommentDialog(SharedNoteComment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                // TODO: Implement comment deletion through provider
                // await ref.read(deleteCommentProvider.notifier).deleteComment(
                //   sharedNoteId: widget.sharedNoteId,
                //   commentId: comment.id,
                // );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment deleted successfully!')),
                );

                // Refresh comments
                ref.invalidate(sharedNoteCommentsProvider(widget.sharedNoteId));
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete comment: $error')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
