import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/note_model.dart';
import '../../models/family_member.dart';
import '../../core/services/user_name_cache_service.dart';
import '../../features/family/providers/auth_providers.dart';

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
  bool _requiresApproval = false;
  NoteModel? _selectedNote;
  List<FamilyMember> _familyMembers = [];
  List<FamilyMember> _filteredMembers = [];
  final Set<String> _selectedMembers = {};
  final UserNameCacheService _userNameCache = UserNameCacheService();
  final Map<String, String> _userNames = {}; // Cache for user names

  // Permission settings
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
        // TODO: Load note from repository
        _selectedNote = NoteModel(
          id: widget.noteId!,
          title: 'Sample Note',
          content: 'Sample content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: [],
          isFavorite: false,
          mode: 'personal',
        );
        _titleController.text = _selectedNote!.title;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
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

  Future<void> _shareNote() async {
    if (_selectedNote == null) return;

    setState(() => _isLoading = true);
    try {
      // Create permission object
      // TODO: Implement permission creation
      /*
      final permission = NotePermission(
        id: 'perm_${DateTime.now().millisecondsSinceEpoch}',
        sharedNoteId: 'shared_${_selectedNote!.id}',
        userId: 'current_user', // TODO: Get current user ID
        familyMemberId: 'member_id', // TODO: Get member ID
        canView: _canView,
        canEdit: _canEdit,
        canComment: _canComment,
        canDelete: false,
        canShare: _canShare,
        canExport: _canExport,
        canInviteCollaborators: false,
        receiveNotifications: _receiveNotifications,
        grantedAt: DateTime.now(),
        grantedBy: 'current_user', // TODO: Get current user ID
        isActive: true,
      );
      */

      // TODO: Call sharing service with permission
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note shared successfully!')),
        );
        context.go('/shared-notes');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing note: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
            onPressed: _isLoading ? null : _shareNote,
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
          ? const Center(child: CircularProgressIndicator())
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
                    _selectedNote!.content.length > 100
                        ? '${_selectedNote!.content.substring(0, 100)}...'
                        : _selectedNote!.content,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
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
                  'No members found matching "${_searchController.text}"',
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
}
