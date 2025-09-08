import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../core/constants/app_colors.dart';
import '../../data/models/note_model.dart';
import '../../models/family_member.dart';
import '../../models/note_permission.dart';
import '../../core/services/user_name_cache_service.dart';
import '../../features/family/providers/auth_providers.dart';
import '../../data/repositories/note_repository.dart';

// T024: Permission level enum for simplified permission management
enum PermissionLevel {
  read,
  write,
  admin,
  custom,
}

class NoteSharingScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteSharingScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteSharingScreen> createState() => _NoteSharingScreenState();
}

class _NoteSharingScreenState extends ConsumerState<NoteSharingScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingNote = false; // T018: Loading state for note retrieval
  String? _noteError; // T017: Error handling for note loading
  bool _requiresApproval = false;
  NoteModel? _selectedNote;
  List<FamilyMember> _familyMembers = [];
  List<FamilyMember> _filteredMembers = [];
  final Set<String> _selectedMembers = {};
  final UserNameCacheService _userNameCache = UserNameCacheService();
  final NoteRepository _noteRepository = NoteRepository(); // T016: Note repository for loading notes
  final Map<String, String> _userNames = {}; // Cache for user names

  // T024: Permission level selection (read/write/admin)
  PermissionLevel _selectedPermissionLevel = PermissionLevel.read;

  // Individual permission settings (for custom level)
  bool _canView = true;
  bool _canComment = false;
  bool _canEdit = false;
  bool _canShare = false;
  bool _canExport = false;
  bool _receiveNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // T024 & T025: Permission level management and inheritance logic
  void _setPermissionLevel(PermissionLevel level) {
    setState(() {
      _selectedPermissionLevel = level;
      _applyPermissionLevel(level);
    });
  }

  // T025: Apply permission inheritance based on selected level
  void _applyPermissionLevel(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.read:
        _canView = true;
        _canComment = false;
        _canEdit = false;
        _canShare = false;
        _canExport = false;
        break;
      case PermissionLevel.write:
        _canView = true;
        _canComment = true;
        _canEdit = true;
        _canShare = false;
        _canExport = false;
        break;
      case PermissionLevel.admin:
        _canView = true;
        _canComment = true;
        _canEdit = true;
        _canShare = true;
        _canExport = true;
        break;
      case PermissionLevel.custom:
        // Keep current custom settings
        break;
    }
  }

  // T025: Get inherited permissions based on family member role
  NotePermission _createInheritedPermission(String userId, String familyMemberId) {
    // Find the family member to get their role
    final member = _familyMembers.firstWhere(
      (m) => m.userId == userId,
      orElse: () => FamilyMember(
        userId: userId,
        familyId: '', // Will be set properly in service
        role: FamilyRole.viewer,
        permissions: const MemberPermissions(
          canInviteMembers: false,
          canRemoveMembers: false,
          canShareNotes: false,
          canEditSharedNotes: false,
          canDeleteSharedNotes: false,
          canManagePermissions: false,
        ),
        joinedAt: DateTime.now(),
        isActive: true,
      ),
    );

    // T025: Apply permission inheritance based on role
    bool canEdit = _canEdit;
    bool canComment = _canComment;
    bool canShare = _canShare;
    bool canExport = _canExport;

    // Inherit restrictions based on family role
    if (member.role == FamilyRole.viewer) {
      // Viewers get read-only access regardless of selected permissions
      canEdit = false;
      canComment = _canComment && member.permissions.canEditSharedNotes;
      canShare = false;
      canExport = _canExport && member.permissions.canShareNotes;
    } else if (member.role == FamilyRole.editor) {
      // Editors can edit if they have the family permission
      canEdit = _canEdit && member.permissions.canEditSharedNotes;
      canComment = _canComment && member.permissions.canEditSharedNotes;
      canShare = _canShare && member.permissions.canShareNotes;
      canExport = _canExport && member.permissions.canShareNotes;
    }
    // Admins and owners get full selected permissions

    return NotePermission(
      id: 'perm_${DateTime.now().millisecondsSinceEpoch}_$userId',
      sharedNoteId: 'shared_${_selectedNote!.id}',
      userId: userId,
      familyMemberId: familyMemberId,
      canView: _canView,
      canEdit: canEdit,
      canComment: canComment,
      canDelete: false, // Only sharer can delete
      canShare: canShare,
      canExport: canExport,
      canInviteCollaborators: false,
      receiveNotifications: _receiveNotifications,
      grantedAt: DateTime.now(),
      grantedBy: '', // Will be set by service
      isActive: true,
    );
  }

  // T022: Validate permission combinations
  String? _validatePermissions() {
    // T022: Basic validation rules
    if (!_canView) {
      return 'View permission is required for all other permissions';
    }

    if (_canEdit && !_canComment) {
      return 'Edit permission requires comment permission';
    }

    if (_canShare && !_canComment) {
      return 'Share permission requires comment permission';
    }

    if (_selectedMembers.isEmpty) {
      return 'Please select at least one family member to share with';
    }

    return null; // No validation errors
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Get current user and family information
      final authState = ref.read(currentFamilyAuthProvider);
      final currentUserId = authState.user?.uid;

      if (authState.hasFamily && currentUserId != null) {
        final familyId = authState.familyId!;

        // Load family members - TODO: Replace with actual service call
        // For now, create mock data
        _familyMembers = [
          FamilyMember(
            userId: 'user1',
            familyId: familyId,
            role: FamilyRole.admin,
            permissions: MemberPermissions(
              canInviteMembers: true,
              canRemoveMembers: true,
              canShareNotes: true,
              canEditSharedNotes: true,
              canDeleteSharedNotes: true,
              canManagePermissions: true,
            ),
            joinedAt: DateTime.now(),
            isActive: true,
          ),
          FamilyMember(
            userId: 'user2',
            familyId: familyId,
            role: FamilyRole.viewer,
            permissions: MemberPermissions(
              canInviteMembers: false,
              canRemoveMembers: false,
              canShareNotes: true,
              canEditSharedNotes: false,
              canDeleteSharedNotes: false,
              canManagePermissions: false,
            ),
            joinedAt: DateTime.now(),
            isActive: true,
          ),
        ];

        // Filter out current user from the list
        _familyMembers = _familyMembers.where((member) => member.userId != currentUserId).toList();
        _filteredMembers = List.from(_familyMembers);

        // Fetch user names for all family members
        await _fetchUserNames();
      } else {
        // User is not part of a family
        _familyMembers = [];
        _filteredMembers = [];
      }

      // Load selected note if provided
      if (widget.noteId != null) {
        // T016: Load note from repository
        await _loadNoteFromRepository(widget.noteId!);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  // T016: Load note from repository with proper error handling
  Future<void> _loadNoteFromRepository(String noteId) async {
    setState(() {
      _isLoadingNote = true;
      _noteError = null;
    });

    try {
      // T017: Implement note data validation and error handling
      final note = await _noteRepository.getNoteById(noteId);

      if (note == null) {
        // T020: Handle note not found scenarios
        setState(() {
          _noteError = 'Note not found. It may have been deleted or you may not have access to it.';
          _isLoadingNote = false;
        });
        return;
      }

      // T017: Validate note data
      if (note.title.isEmpty) {
        setState(() {
          _noteError = 'Note title is missing or invalid.';
          _isLoadingNote = false;
        });
        return;
      }

      setState(() {
        _selectedNote = note;
        _titleController.text = note.title;
        _isLoadingNote = false;
      });

    } catch (e) {
      // T017: Comprehensive error handling
      debugPrint('Error loading note: $e');
      setState(() {
        _noteError = 'Failed to load note. Please try again.';
        _isLoadingNote = false;
      });
    }
  }

  Future<void> _fetchUserNames() async {
    final userIds = _familyMembers.map((member) => member.userId).toList();
    final userNames = await _userNameCache.getUserNames(userIds);

    setState(() {
      _userNames.addAll(userNames);
    });
  }

  void _filterMembers(String query) {
    if (query.isEmpty) {
      _filteredMembers = List.from(_familyMembers);
    } else {
      _filteredMembers = _familyMembers.where((member) {
        final displayName = _userNames[member.userId] ?? 'Unknown User';
        return displayName.toLowerCase().contains(query.toLowerCase()) ||
               member.role.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    setState(() {});
  }

  // T013: Implement member ID resolution for permission creation
  Future<Map<String, String>> _resolveMemberIds(List<String> userIds) async {
    final memberIds = <String, String>{};

    // For now, create mock member IDs based on user IDs
    // TODO: Replace with actual service call to resolve member IDs
    for (final userId in userIds) {
      // In a real implementation, this would query the family member repository
      // to get the actual member ID for the user
      memberIds[userId] = 'member_$userId';
    }

    return memberIds;
  }





  // T026: Enhanced sharing service integration with proper error handling
  Future<void> _shareNoteWithService() async {
    if (_selectedNote == null) return;

    // T011: Get current user ID from auth state
    final authState = ref.read(currentFamilyAuthProvider);
    final currentUserId = authState.user?.uid;

    // T014: Add user authentication state validation
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to share notes')),
        );
      }
      return;
    }

    // T014: Validate family membership
    if (!authState.hasFamily) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be part of a family to share notes')),
        );
      }
      return;
    }

    // T022: Validate permissions before sharing
    final validationError = _validatePermissions();
    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationError)),
        );
      }
      return;
    }

    // T030: Add sharing progress indicators
    setState(() => _isLoading = true);

    try {
      // T013: Resolve member IDs for selected users
      final memberIds = await _resolveMemberIds(_selectedMembers.toList());

      // T021: Create permission objects with inheritance logic
      final permissions = <NotePermission>[];
      for (final memberId in memberIds.entries) {
        final permission = _createInheritedPermission(memberId.key, memberId.value);
        permissions.add(permission);
      }

      // T026: Call sharing service with permission persistence
      // For now, create a mock service call that simulates the real implementation
      final sharedNote = await _callSharingService(
        noteId: _selectedNote!.id,
        title: _selectedNote!.title,
        permissions: permissions,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        requiresApproval: _requiresApproval,
        currentUserId: currentUserId,
        familyId: authState.familyId!,
      );

      // Log successful sharing for debugging
      debugPrint('Note shared successfully: ${sharedNote['id']}');

      // T027: Add success feedback for sharing operations
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note shared successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to shared notes list
                context.go('/shared-notes');
              },
            ),
          ),
        );

        // T028: Update UI state after successful sharing
        setState(() {
          _selectedMembers.clear();
          _descriptionController.clear();
          _selectedPermissionLevel = PermissionLevel.read;
          _applyPermissionLevel(PermissionLevel.read);
        });

        // T029: Implement optimistic UI updates for better UX
        _showSuccessAnimation();

        // Navigate after showing success animation
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/shared-notes');
          }
        });
      }
    } catch (e) {
      // T022: Enhanced error handling for sharing failures
      if (mounted) {
        String errorMessage = 'Error sharing note';
        Color backgroundColor = Colors.red;

        if (e.toString().contains('permission')) {
          errorMessage = 'You do not have permission to share this note';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection and try again';
          backgroundColor = Colors.orange;
        } else if (e.toString().contains('already shared')) {
          errorMessage = 'This note has already been shared';
        } else if (e.toString().contains('validation')) {
          errorMessage = 'Please check your input and try again';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _shareNoteWithService,
            ),
          ),
        );
      }
    } finally {
      // T030: Remove sharing progress indicators
      setState(() => _isLoading = false);
    }
  }

  // T026: Mock service call that simulates real sharing service integration
  Future<Map<String, dynamic>> _callSharingService({
    required String noteId,
    required String title,
    required List<NotePermission> permissions,
    String? description,
    required bool requiresApproval,
    required String currentUserId,
    required String familyId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate potential errors (remove this in production)
    if (Random().nextDouble() < 0.1) { // 10% chance of error
      throw Exception('Network error occurred while sharing note');
    }

    // Create mock shared note response
    return {
      'id': 'shared_${DateTime.now().millisecondsSinceEpoch}',
      'noteId': noteId,
      'title': title,
      'sharedBy': currentUserId,
      'familyId': familyId,
      'permissions': permissions.map((p) => p.toJson()).toList(),
      'description': description,
      'requiresApproval': requiresApproval,
      'createdAt': DateTime.now(),
      'status': requiresApproval ? 'pending' : 'approved',
    };
  }

  // T029: Success animation for optimistic UI updates
  void _showSuccessAnimation() {
    if (!mounted) return;

    // Show a brief success overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Note Shared Successfully!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your family members have been notified',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
  Widget _buildSharingProgressIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sharing note...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Creating permissions and notifying family members',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // T029: Show selected members being shared with
          if (_selectedMembers.isNotEmpty) ...[
            Text(
              'Sharing with ${_selectedMembers.length} family member${_selectedMembers.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Note'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _shareNoteWithService,
            child: Text(
              'Share',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildSharingProgressIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Note selection
                  if (_selectedNote != null) ...[
                    _buildNotePreview(),
                    const SizedBox(height: 24),
                  ],

                  // Sharing details
                  _buildSharingDetails(),

                  const SizedBox(height: 24),

                  // Family members selection
                  _buildFamilyMembersSelection(),

                  const SizedBox(height: 24),

                  // Permissions
                  _buildPermissionsSection(),

                  const SizedBox(height: 24),

                  // Additional options
                  _buildAdditionalOptions(),
                ],
              ),
            ),
    );
  }

  Widget _buildNotePreview() {
    // T018: Add loading states for note retrieval
    if (_isLoadingNote) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Note to Share',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // T017: Handle note loading errors
    if (_noteError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Note to Share',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Error Loading Note',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _noteError!,
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: widget.noteId != null ? () => _loadNoteFromRepository(widget.noteId!) : null,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // T020: Handle case when no note is selected
    if (_selectedNote == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Note to Share',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No note selected',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // T019: Add note preview before sharing
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Note to Share',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedNote!.mode == 'personal' ? Colors.blue[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedNote!.mode.toUpperCase(),
                    style: TextStyle(
                      color: _selectedNote!.mode == 'personal' ? Colors.blue[800] : Colors.green[800],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                    _selectedNote!.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedNote!.content.length > 200
                        ? '${_selectedNote!.content.substring(0, 200)}...'
                        : _selectedNote!.content,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (_selectedNote!.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _selectedNote!.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 12,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Created: ${_formatDate(_selectedNote!.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharingDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sharing Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Shared Note Title',
                hintText: 'Enter a title for the shared note',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Why are you sharing this note?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMembersSelection() {
    if (_familyMembers.isEmpty) {
      return _buildEmptyFamilyState();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share with Family Members',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search members',
                hintText: 'Type name or role...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterMembers,
            ),
            const SizedBox(height: 16),

            // Members list
            ..._filteredMembers.map((member) => CheckboxListTile(
              title: Text(_userNames[member.userId] ?? 'Loading...'),
              subtitle: Text('Role: ${member.role.name}'),
              value: _selectedMembers.contains(member.userId),
              onChanged: (selected) {
                setState(() {
                  if (selected ?? false) {
                    _selectedMembers.add(member.userId);
                  } else {
                    _selectedMembers.remove(member.userId);
                  }
                });
              },
            )),

            if (_filteredMembers.isEmpty && _searchController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'No members found matching "$_searchController.text"',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // T024: Permission level selection buttons
            Text(
              'Permission Level',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPermissionLevelButton(
                    PermissionLevel.read,
                    'Read',
                    'View only',
                    Icons.visibility,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPermissionLevelButton(
                    PermissionLevel.write,
                    'Write',
                    'View & edit',
                    Icons.edit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPermissionLevelButton(
                    PermissionLevel.admin,
                    'Admin',
                    'Full access',
                    Icons.admin_panel_settings,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPermissionLevelButton(
                    PermissionLevel.custom,
                    'Custom',
                    'Set manually',
                    Icons.settings,
                  ),
                ),
              ],
            ),

            // Show individual permissions only for custom level
            if (_selectedPermissionLevel == PermissionLevel.custom) ...[
              const SizedBox(height: 24),
              Text(
                'Custom Permissions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Can View'),
                subtitle: const Text('Allow members to view the note'),
                value: _canView,
                onChanged: (value) => setState(() => _canView = value),
              ),
              SwitchListTile(
                title: const Text('Can Comment'),
                subtitle: const Text('Allow members to add comments'),
                value: _canComment,
                onChanged: _canView ? (value) => setState(() => _canComment = value) : null,
              ),
              SwitchListTile(
                title: const Text('Can Edit'),
                subtitle: const Text('Allow members to edit the note'),
                value: _canEdit,
                onChanged: _canView ? (value) => setState(() => _canEdit = value) : null,
              ),
              SwitchListTile(
                title: const Text('Can Share'),
                subtitle: const Text('Allow members to share with others'),
                value: _canShare,
                onChanged: _canView ? (value) => setState(() => _canShare = value) : null,
              ),
              SwitchListTile(
                title: const Text('Can Export'),
                subtitle: const Text('Allow members to export the note'),
                value: _canExport,
                onChanged: _canView ? (value) => setState(() => _canExport = value) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // T024: Helper method to build permission level buttons
  Widget _buildPermissionLevelButton(
    PermissionLevel level,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedPermissionLevel == level;

    return InkWell(
      onTap: () => _setPermissionLevel(level),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.1) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryBlue : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.primaryBlue : Colors.black,
                fontSize: 12,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Requires Approval'),
              subtitle: const Text('Family admin must approve before sharing'),
              value: _requiresApproval,
              onChanged: (value) => setState(() => _requiresApproval = value),
            ),
            SwitchListTile(
              title: const Text('Receive Notifications'),
              subtitle: const Text('Get notified about changes and comments'),
              value: _receiveNotifications,
              onChanged: (value) => setState(() => _receiveNotifications = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFamilyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Family Members',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to be part of a family to share notes. Create or join a family first.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.go('/family'),
              icon: const Icon(Icons.group_add),
              label: const Text('Manage Family'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format dates
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
