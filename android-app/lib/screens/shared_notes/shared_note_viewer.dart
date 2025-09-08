import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shared_note.dart';
import '../../models/shared_note_comment.dart';
import '../../models/note_permission.dart';
import '../../core/services/user_name_cache_service.dart';
import '../../features/family/providers/auth_providers.dart';
import '../../features/family/services/shared_notes_service.dart';
import 'comment_widget.dart';

// T043: Comment sorting options
enum CommentSortOption { newestFirst, oldestFirst }

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
  String? _sharedByName;
  final UserNameCacheService _userNameCache = UserNameCacheService();
  final TextEditingController _commentController = TextEditingController();

  // T041-T045: Comment loading, pagination, sorting, and caching
  bool _isLoadingComments = false;
  bool _hasMoreComments = true;
  static const int _commentsPageSize = 20;
  DocumentSnapshot? _lastCommentDocument; // ignore: unused_field - Will be used when service integration is complete
  final Map<String, List<SharedNoteComment>> _commentCache = {}; // T045: Comment caching
  // TODO: Initialize with proper dependency injection when service integration is complete
  late SharedNotesService _sharedNotesService; // ignore: unused_field

  // T043: Comment sorting
  CommentSortOption _commentSort = CommentSortOption.newestFirst;

  // T046-T050: Comment creation enhancements
  bool _isAddingComment = false;
  static const int _maxCommentLength = 1000;
  static const int _warningCommentLength = 800;
  String? _commentDraft;
  bool _showCharacterWarning = false;

  // T051-T055: Reply system enhancements
  bool _isReplying = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;
  final TextEditingController _replyController = TextEditingController();
  static const int _maxReplyDepth = 5;
  bool _showReplyPreview = false;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize SharedNotesService with proper dependency injection
    // For now, we'll use a placeholder that will be replaced with proper DI
    _loadSharedNote();
    _loadCommentDraft(); // T050: Load saved comment draft
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose(); // T051: Clean up reply controller
    _saveCommentDraft(); // T050: Save draft before disposing
    super.dispose();
  }

  Future<void> _loadSharedNote() async {
    setState(() => _isLoading = true);
    try {
      // T012: Get current user from Riverpod auth provider
      final authState = ref.read(currentFamilyAuthProvider);

      // T014: Add user authentication state validation
      if (authState.user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to view shared notes')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      _currentUserId = authState.user!.uid;
      _currentUserDisplayName = authState.user!.displayName ?? 'Current User';

      // T014: Validate family membership if needed
      if (!authState.hasFamily) {
        // Note: For viewing shared notes, we might allow access even without family membership
        // depending on the sharing model. This could be adjusted based on requirements.
      }

      // TODO: Load shared note from service
      // For now, create mock data
      _sharedNote = SharedNote(
        id: widget.sharedNoteId,
        noteId: 'note123',
        familyId: authState.familyId ?? 'family1',
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

      // Fetch the name of the user who shared the note
      await _fetchSharedByName();

      // T041: Load comments from service instead of mock data
      await _loadComments();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading shared note: $e');
      setState(() => _isLoading = false);
    }
  }

  // T041: Load comments from service with pagination and caching
  Future<void> _loadComments({bool loadMore = false}) async {
    if (_isLoadingComments || (!loadMore && !loadMore && _comments.isNotEmpty)) return;

    setState(() => _isLoadingComments = true);

    try {
      // T045: Check cache first
      if (!loadMore && _commentCache.containsKey(widget.sharedNoteId)) {
        setState(() {
          _comments = _commentCache[widget.sharedNoteId]!;
        });
        setState(() => _isLoadingComments = false);
        return;
      }

      // TODO: Replace with actual service call when DI is set up
      // For now, use mock data with pagination simulation
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

      List<SharedNoteComment> newComments = [];

      if (!loadMore) {
        // T042: Load initial page
        newComments = _generateMockComments(_commentsPageSize);
        _lastCommentDocument = null; // Reset pagination
        _hasMoreComments = newComments.length >= _commentsPageSize;
      } else {
        // T042: Load more comments for pagination
        if (!_hasMoreComments) return;

        newComments = _generateMockComments(_commentsPageSize);
        _hasMoreComments = newComments.length >= _commentsPageSize;

        if (newComments.isNotEmpty) {
          // Simulate DocumentSnapshot for pagination
          _lastCommentDocument = null; // In real implementation, this would be the last document
        }
      }

      setState(() {
        if (!loadMore) {
          _comments = newComments;
          // T045: Cache the comments
          _commentCache[widget.sharedNoteId] = newComments;
        } else {
          _comments.addAll(newComments);
          // T045: Update cache
          _commentCache[widget.sharedNoteId] = _comments;
        }
      });

      // T043: Apply sorting after loading
      _sortComments();

    } catch (e) {
      debugPrint('Error loading comments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingComments = false);
    }
  }

  // T043: Sort comments based on current sort option
  void _sortComments() {
    setState(() {
      if (_commentSort == CommentSortOption.newestFirst) {
        _comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        _comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
    });
  }

  // T043: Change comment sort option
  void _changeCommentSort(CommentSortOption sortOption) {
    setState(() {
      _commentSort = sortOption;
      _sortComments();
    });
  }

  // T042: Load more comments for pagination
  Future<void> _loadMoreComments() async {
    if (_isLoadingComments || !_hasMoreComments) return;
    await _loadComments(loadMore: true);
  }

  // Mock comment generation for development (replace with actual service)
  List<SharedNoteComment> _generateMockComments(int count) {
    final List<SharedNoteComment> mockComments = [];
    final baseTime = DateTime.now().subtract(Duration(hours: _comments.length));

    for (int i = 0; i < count; i++) {
      mockComments.add(SharedNoteComment(
        id: 'comment_${_comments.length + i + 1}',
        sharedNoteId: widget.sharedNoteId,
        userId: 'user${(_comments.length + i) % 3 + 1}',
        userDisplayName: ['Alice Johnson', 'Bob Smith', 'Carol Williams'][(_comments.length + i) % 3],
        content: 'This is comment #${_comments.length + i + 1}. Great insights shared here!',
        createdAt: baseTime.subtract(Duration(minutes: i * 30)),
        isEdited: i % 5 == 0,
        likedBy: i % 2 == 0 ? ['user1', 'user2'] : [],
        replies: [],
      ));
    }

    return mockComments;
  }

  Future<void> _fetchSharedByName() async {
    if (_sharedNote == null) return;

    final name = await _userNameCache.getUserName(_sharedNote!.sharedBy);
    if (mounted) {
      setState(() {
        _sharedByName = name ?? 'Unknown User';
      });
    }
  }

  Future<void> _addComment() async {
    // T047: Comment input validation
    final commentText = _commentController.text.trim();
    if (!_validateComment(commentText)) return;

    setState(() => _isAddingComment = true);

    try {
      // T046: Add comment via service (placeholder for now)
      // TODO: Replace with actual service call when DI is set up
      final newComment = SharedNoteComment(
        id: 'comment${DateTime.now().millisecondsSinceEpoch}',
        sharedNoteId: widget.sharedNoteId,
        userId: _currentUserId ?? 'current_user',
        userDisplayName: _currentUserDisplayName ?? 'Current User',
        content: commentText,
        createdAt: DateTime.now(),
        isEdited: false,
        likedBy: [],
        replies: [],
      );

      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
        _commentDraft = null; // T050: Clear draft after successful submission
        // T045: Update cache
        _commentCache[widget.sharedNoteId] = _comments;
      });

      // T043: Re-sort comments after adding new one
      _sortComments();

      // T048: Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added successfully!')),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    } finally {
      setState(() => _isAddingComment = false);
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

      // TODO: Update like status via service - T066: Service integration
      // For now, keep optimistic updates
      // await _sharedNotesService.toggleCommentLike(
      //   sharedNoteId: widget.sharedNoteId,
      //   commentId: commentId,
      // );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating like: $e')),
      );
    }
  }

  // T047: Comment input validation
  bool _validateComment(String text) {
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty')),
      );
      return false;
    }

    if (text.length > _maxCommentLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment cannot exceed $_maxCommentLength characters')),
      );
      return false;
    }

    // Check for basic content validation
    if (text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment must be at least 2 characters long')),
      );
      return false;
    }

    return true;
  }

  // T049: Check if comment/reply is approaching character limit
  void _checkCharacterLimit(String text) {
    final shouldShowWarning = text.length > _warningCommentLength && text.length <= _maxCommentLength;
    if (_showCharacterWarning != shouldShowWarning) {
      setState(() {
        _showCharacterWarning = shouldShowWarning;
      });
    }
  }

  // T050: Save comment draft
  void _saveCommentDraft() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      _commentDraft = text;
      // TODO: Save to persistent storage (SharedPreferences, local database, etc.)
      // For now, just keep in memory
    }
  }

  // T050: Load comment draft
  void _loadCommentDraft() {
    if (_commentDraft != null && _commentDraft!.isNotEmpty) {
      _commentController.text = _commentDraft!;
    }
  }

  // T051: Enhanced reply functionality with threading context
  Future<void> _handleReply(String commentId) async {
    final comment = _comments.firstWhere((c) => c.id == commentId);

    // T054: Check reply depth limit
    if (_getReplyDepth(comment) >= _maxReplyDepth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum reply depth reached (5 levels)')),
      );
      return;
    }

    setState(() {
      _isReplying = true;
      _replyingToCommentId = commentId;
      _replyingToUserName = comment.userDisplayName;
      _replyController.clear();
    });
  }

  // T061: Handle comment editing
  Future<void> _handleEdit(String commentId, String newContent) async {
    try {
      // TODO: Call the actual service method
      // await _sharedNotesService.updateComment(
      //   sharedNoteId: widget.sharedNoteId,
      //   commentId: commentId,
      //   content: newContent,
      // );

      // For now, update local state
      setState(() {
        final commentIndex = _comments.indexWhere((c) => c.id == commentId);
        if (commentIndex != -1) {
          _comments[commentIndex] = _comments[commentIndex].copyWith(
            content: newContent,
            updatedAt: DateTime.now(),
            isEdited: true,
          );
        }
      });

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

  // T062: Handle comment deletion with soft delete
  Future<void> _handleDelete(String commentId) async {
    try {
      // TODO: Call the actual service method
      // await _sharedNotesService.deleteComment(
      //   sharedNoteId: widget.sharedNoteId,
      //   commentId: commentId,
      // );

      // For now, implement soft delete locally
      setState(() {
        final commentIndex = _comments.indexWhere((c) => c.id == commentId);
        if (commentIndex != -1) {
          _comments[commentIndex] = _comments[commentIndex].copyWith(
            isDeleted: true,
            deletedAt: DateTime.now(),
          );
        }
      });

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

  // T054: Calculate reply depth for depth limiting
  int _getReplyDepth(SharedNoteComment comment) {
    int depth = 0;
    SharedNoteComment current = comment;

    // Find the root comment to calculate depth
    while (current.parentCommentId != null) {
      depth++;
      // In a real implementation, you'd look up the parent comment
      // For now, we'll use a simple estimation
      if (depth >= _maxReplyDepth) break;
    }

    return depth;
  }

  // T051: Cancel reply mode
  void _cancelReply() {
    setState(() {
      _isReplying = false;
      _replyingToCommentId = null;
      _replyingToUserName = null;
      _replyController.clear();
      _showReplyPreview = false;
    });
  }

  // T051: Submit reply with validation
  Future<void> _submitReply() async {
    if (_replyingToCommentId == null) return;

    final replyText = _replyController.text.trim();

    // T053: Reply validation
    if (!_validateReply(replyText)) return;

    setState(() => _isAddingComment = true);

    try {
      // T051: Add reply via service (placeholder for now)
      final reply = SharedNoteComment(
        id: 'reply${DateTime.now().millisecondsSinceEpoch}',
        sharedNoteId: widget.sharedNoteId,
        userId: _currentUserId ?? 'current_user',
        userDisplayName: _currentUserDisplayName ?? 'Current User',
        content: replyText,
        createdAt: DateTime.now(),
        isEdited: false,
        likedBy: [],
        replies: [],
        parentCommentId: _replyingToCommentId,
      );

      // Add reply to the parent comment
      final parentIndex = _comments.indexWhere((c) => c.id == _replyingToCommentId);
      if (parentIndex != -1) {
        final parentComment = _comments[parentIndex];
        final updatedReplies = List<SharedNoteComment>.from(parentComment.replies)..add(reply);

        setState(() {
          _comments[parentIndex] = parentComment.copyWith(replies: updatedReplies);
          // T045: Update cache
          _commentCache[widget.sharedNoteId] = _comments;
        });
      }

      // T048: Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply added successfully!')),
        );
      }

      _cancelReply(); // T051: Exit reply mode after successful submission

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding reply: $e')),
        );
      }
    } finally {
      setState(() => _isAddingComment = false);
    }
  }

  // T053: Reply validation
  bool _validateReply(String text) {
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply cannot be empty')),
      );
      return false;
    }

    if (text.length > _maxCommentLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reply cannot exceed $_maxCommentLength characters')),
      );
      return false;
    }

    if (text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply must be at least 2 characters long')),
      );
      return false;
    }

    return true;
  }

  // T055: Toggle reply preview
  void _toggleReplyPreview() {
    setState(() {
      _showReplyPreview = !_showReplyPreview;
    });
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

          // T051: Reply input (when replying to a comment)
          if (_canComment && _isReplying) _buildReplyInput(),
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
                  _sharedByName != null ? 'Shared by $_sharedByName' : 'Shared by ${_sharedNote!.sharedBy}',
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
        // T043 & T044: Comments header with count and sorting
        Row(
          children: [
            Expanded(
              child: Text(
                'Comments (${_comments.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // T043: Sort dropdown
            PopupMenuButton<CommentSortOption>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort comments',
              onSelected: _changeCommentSort,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: CommentSortOption.newestFirst,
                  child: Text('Newest First'),
                ),
                const PopupMenuItem(
                  value: CommentSortOption.oldestFirst,
                  child: Text('Oldest First'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Comments list with pagination
        if (_comments.isEmpty && !_isLoadingComments)
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length + (_isLoadingComments ? 1 : 0) + (_hasMoreComments ? 1 : 0),
            itemBuilder: (context, index) {
              // T042: Loading indicator for pagination
              if (index == _comments.length && _isLoadingComments) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // T042: Load more button for pagination
              if (index == _comments.length && _hasMoreComments && !_isLoadingComments) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _loadMoreComments,
                      child: const Text('Load More Comments'),
                    ),
                  ),
                );
              }

              // Regular comment
              if (index < _comments.length) {
                final comment = _comments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CommentWidget(
                    comment: comment,
                    onReply: _handleReply,
                    onLike: _handleLike,
                    onEdit: _handleEdit, // T061: Added edit handler
                    onDelete: _handleDelete, // T062: Added delete handler
                    currentUserId: _currentUserId ?? '',
                    sharedNoteId: widget.sharedNoteId,
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _buildCommentInput() {
    final commentText = _commentController.text;
    final characterCount = commentText.length;
    final isNearLimit = characterCount > _warningCommentLength;
    final isOverLimit = characterCount > _maxCommentLength;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // T049: Character count and warning
          if (_showCharacterWarning || isNearLimit || isOverLimit)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    isOverLimit ? Icons.warning : Icons.info_outline,
                    size: 16,
                    color: isOverLimit ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOverLimit
                        ? 'Comment too long ($characterCount/$_maxCommentLength)'
                        : 'Approaching character limit ($characterCount/$_maxCommentLength)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverLimit ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: InputBorder.none,
                    // T047: Visual feedback for validation
                    filled: isOverLimit,
                    fillColor: isOverLimit ? Colors.red.withValues(alpha: 0.1) : null,
                  ),
                  maxLines: null,
                  maxLength: _maxCommentLength + 50, // Allow slight overflow for UX
                  textInputAction: TextInputAction.send,
                  onChanged: (text) {
                    // T049: Check character limits
                    _checkCharacterLimit(text);
                    // T050: Auto-save draft
                    _saveCommentDraft();
                  },
                  onSubmitted: (_) => _addComment(),
                ),
              ),
              const SizedBox(width: 8),
              // T046: Loading state for comment submission
              if (_isAddingComment)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: (commentText.trim().isEmpty || isOverLimit) ? null : _addComment,
                  color: AppColors.primaryBlue,
                  tooltip: 'Send comment',
                ),
            ],
          ),

          // T050: Draft indicator
          if (_commentDraft != null && _commentDraft!.isNotEmpty && commentText.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.save, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Draft saved',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      _commentController.text = _commentDraft!;
                      _commentDraft = null;
                    },
                    child: const Text('Restore'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // T052: Reply input UI with threading context
  Widget _buildReplyInput() {
    final replyText = _replyController.text;
    final characterCount = replyText.length;
    final isNearLimit = characterCount > _warningCommentLength;
    final isOverLimit = characterCount > _maxCommentLength;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // T052: Reply context header
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.reply, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Replying to ${_replyingToUserName ?? 'user'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: _cancelReply,
                  tooltip: 'Cancel reply',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // T049: Character count and warning for replies
          if (_showCharacterWarning || isNearLimit || isOverLimit)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    isOverLimit ? Icons.warning : Icons.info_outline,
                    size: 16,
                    color: isOverLimit ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOverLimit
                        ? 'Reply too long ($characterCount/$_maxCommentLength)'
                        : 'Approaching character limit ($characterCount/$_maxCommentLength)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverLimit ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // T055: Reply preview toggle
          if (replyText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _toggleReplyPreview,
                    icon: Icon(
                      _showReplyPreview ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                    ),
                    label: Text(_showReplyPreview ? 'Hide Preview' : 'Show Preview'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

          // T055: Reply preview
          if (_showReplyPreview && replyText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preview:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    replyText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: 'Write a reply...',
                    border: InputBorder.none,
                    // T053: Visual feedback for validation
                    filled: isOverLimit,
                    fillColor: isOverLimit ? Colors.red.withValues(alpha: 0.1) : null,
                  ),
                  maxLines: null,
                  maxLength: _maxCommentLength + 50, // Allow slight overflow for UX
                  textInputAction: TextInputAction.send,
                  onChanged: (text) {
                    // T049: Check character limits
                    _checkCharacterLimit(text);
                  },
                  onSubmitted: (_) => _submitReply(),
                ),
              ),
              const SizedBox(width: 8),
              // T051: Loading state for reply submission
              if (_isAddingComment)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: (replyText.trim().isEmpty || isOverLimit) ? null : _submitReply,
                      color: AppColors.primaryBlue,
                      tooltip: 'Send reply',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _cancelReply,
                      tooltip: 'Cancel reply',
                    ),
                  ],
                ),
            ],
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
