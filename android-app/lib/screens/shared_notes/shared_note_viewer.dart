import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shared_note.dart';
import '../../models/shared_note_comment.dart';
import '../../models/note_permission.dart';
import 'comment_widget.dart';

class SharedNoteViewer extends ConsumerStatefulWidget {
  final String sharedNoteId;

  const SharedNoteViewer({super.key, required this.sharedNoteId});

  @override
  ConsumerState<SharedNoteViewer> createState() => _SharedNoteViewerState();
}

class _SharedNoteViewerState extends ConsumerState<SharedNoteViewer> {
  SharedNote? _sharedNote;
  List<SharedNoteComment> _comments = [];
  bool _isLoading = true;
  bool _canEdit = false;
  bool _canComment = false;
  String? _currentUserId;
  String? _currentUserDisplayName;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSharedNote();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSharedNote() async {
    setState(() => _isLoading = true);
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      _currentUserId = currentUser?.uid ?? 'current_user';
      _currentUserDisplayName = currentUser?.displayName ?? 'Current User';

      // TODO: Load shared note from service
      // For now, create mock data
      _sharedNote = SharedNote(
        id: widget.sharedNoteId,
        noteId: 'note123',
        familyId: 'family1',
        sharedBy: 'user1',
        sharedAt: DateTime.now().subtract(const Duration(hours: 2)),
        title: 'Sample Shared Note',
        description: 'This is a sample shared note for demonstration',
        permission: NotePermission(
          id: 'perm1',
          sharedNoteId: widget.sharedNoteId,
          userId: _currentUserId!,
          familyMemberId: 'member1',
          canView: true,
          canEdit: true,
          canComment: true,
          canDelete: false,
          canShare: false,
          canExport: true,
          canInviteCollaborators: false,
          receiveNotifications: true,
          grantedAt: DateTime.now(),
          grantedBy: 'user1',
          isActive: true,
        ),
        requiresApproval: false,
        status: SharingStatus.approved,
        approvedBy: 'admin',
        approvedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      // Set permissions based on the permission object
      _canEdit = _sharedNote!.permission.canEdit;
      _canComment = _sharedNote!.permission.canComment;

      // TODO: Load comments
      _comments = [
        SharedNoteComment(
          id: 'comment1',
          sharedNoteId: widget.sharedNoteId,
          userId: 'user2',
          userDisplayName: 'Jane Smith',
          content: 'This is a great note! Thanks for sharing.',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          isEdited: false,
          likedBy: ['user1'],
          replies: [],
        ),
        SharedNoteComment(
          id: 'comment2',
          sharedNoteId: widget.sharedNoteId,
          userId: 'user1',
          userDisplayName: 'John Doe',
          content: 'Glad you found it helpful!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          isEdited: false,
          likedBy: [],
          replies: [],
        ),
      ];

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading shared note: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      // TODO: Add comment via service
      final newComment = SharedNoteComment(
        id: 'comment${DateTime.now().millisecondsSinceEpoch}',
        sharedNoteId: widget.sharedNoteId,
        userId: _currentUserId ?? 'current_user',
        userDisplayName: _currentUserDisplayName ?? 'Current User',
        content: _commentController.text.trim(),
        createdAt: DateTime.now(),
        isEdited: false,
        likedBy: [],
        replies: [],
      );

      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    }
  }

  Future<void> _handleLike(String commentId) async {
    try {
      setState(() {
        final commentIndex = _comments.indexWhere((c) => c.id == commentId);
        if (commentIndex != -1) {
          final comment = _comments[commentIndex];
          final currentUserId = _currentUserId ?? 'current_user';
          final likedBy = List<String>.from(comment.likedBy);

          if (likedBy.contains(currentUserId)) {
            likedBy.remove(currentUserId);
          } else {
            likedBy.add(currentUserId);
          }

          _comments[commentIndex] = comment.copyWith(likedBy: likedBy);
        }
      });

      // TODO: Update like status via service
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating like: $e')),
      );
    }
  }

  Future<void> _handleReply(String commentId) async {
    // TODO: Implement reply functionality
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reply functionality coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shared Note')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_sharedNote == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shared Note')),
        body: const Center(
          child: Text('Note not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_sharedNote!.title),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Navigate to edit mode
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit functionality coming soon!')),
                );
              },
              tooltip: 'Edit Note',
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Note content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Note metadata
                  _buildNoteMetadata(),

                  const SizedBox(height: 16),

                  // Note content
                  _buildNoteContent(),

                  const SizedBox(height: 24),

                  // Comments section
                  _buildCommentsSection(),
                ],
              ),
            ),
          ),

          // Comment input (only if can comment)
          if (_canComment) _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildNoteMetadata() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Shared by ${_sharedNote!.sharedBy}', // TODO: Get actual name
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(_sharedNote!.sharedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (_sharedNote!.description != null) ...[
              const SizedBox(height: 8),
              Text(
                _sharedNote!.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteContent() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Note Content',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // TODO: Replace with actual note content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'This is where the actual note content would be displayed.\n\n'
                'It would include the full text, formatting, and any attachments.\n\n'
                'For now, this is just a placeholder.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Comments (${_comments.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_comments.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  // TODO: Toggle comments visibility
                },
                icon: const Icon(Icons.expand_more),
                label: const Text('Show All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_comments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No comments yet. Be the first to comment!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._comments.map((comment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CommentWidget(
              comment: comment,
              onReply: _handleReply,
              onLike: _handleLike,
              currentUserId: _currentUserId,
            ),
          )),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _addComment(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _commentController.text.trim().isEmpty ? null : _addComment,
            color: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        // TODO: Implement export
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export functionality coming soon!')),
        );
        break;
      case 'share':
        // TODO: Implement share
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share functionality coming soon!')),
        );
        break;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
