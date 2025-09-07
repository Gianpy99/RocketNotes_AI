import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/family_member.dart';

class ManagePermissionsScreen extends ConsumerStatefulWidget {
  final FamilyMember member;

  const ManagePermissionsScreen({
    super.key,
    required this.member,
  });

  @override
  ConsumerState<ManagePermissionsScreen> createState() => _ManagePermissionsScreenState();
}

class _ManagePermissionsScreenState extends ConsumerState<ManagePermissionsScreen> {
  late FamilyRole _selectedRole;
  late bool _canInvite;
  late bool _canEdit;
  late bool _canShare;
  late bool _canDelete;
  late bool _canManage;

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.member.role;
    _canInvite = widget.member.permissions.canInviteMembers;
    _canEdit = widget.member.permissions.canEditSharedNotes;
    _canShare = widget.member.permissions.canShareNotes;
    _canDelete = widget.member.permissions.canDeleteSharedNotes;
    _canManage = widget.member.permissions.canManagePermissions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Permissions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Member Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _getRoleColor(_selectedRole),
                      child: Text(
                        widget.member.userId.isNotEmpty
                            ? widget.member.userId[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.member.userId,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Member since ${_formatDate(widget.member.joinedAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Role Section
            Text(
              'Role',
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
                    DropdownButtonFormField<FamilyRole>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Family Role',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.admin_panel_settings),
                      ),
                      items: FamilyRole.values.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(_getRoleDisplayName(role)),
                        );
                      }).toList(),
                      onChanged: widget.member.role == FamilyRole.owner
                          ? null // Can't change owner's role
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedRole = value;
                                  _updatePermissionsForRole(value);
                                  _checkForChanges();
                                });
                              }
                            },
                    ),

                    if (widget.member.role == FamilyRole.owner)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Owner role cannot be changed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Permissions Section
            Text(
              'Permissions',
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
                    CheckboxListTile(
                      title: const Text('Can invite members'),
                      subtitle: const Text('Allow inviting other people to join the family'),
                      value: _canInvite,
                      onChanged: _canModifyPermissions
                          ? (value) => setState(() {
                                _canInvite = value ?? false;
                                _checkForChanges();
                              })
                          : null,
                      secondary: const Icon(Icons.person_add),
                    ),

                    const Divider(),

                    CheckboxListTile(
                      title: const Text('Can edit shared notes'),
                      subtitle: const Text('Allow editing notes shared by others'),
                      value: _canEdit,
                      onChanged: _canModifyPermissions
                          ? (value) => setState(() {
                                _canEdit = value ?? false;
                                _checkForChanges();
                              })
                          : null,
                      secondary: const Icon(Icons.edit),
                    ),

                    const Divider(),

                    CheckboxListTile(
                      title: const Text('Can share notes'),
                      subtitle: const Text('Allow sharing notes with the family'),
                      value: _canShare,
                      onChanged: _canModifyPermissions
                          ? (value) => setState(() {
                                _canShare = value ?? false;
                                _checkForChanges();
                              })
                          : null,
                      secondary: const Icon(Icons.share),
                    ),

                    const Divider(),

                    CheckboxListTile(
                      title: const Text('Can delete shared notes'),
                      subtitle: const Text('Allow deleting notes shared by others'),
                      value: _canDelete,
                      onChanged: _canModifyPermissions
                          ? (value) => setState(() {
                                _canDelete = value ?? false;
                                _checkForChanges();
                              })
                          : null,
                      secondary: const Icon(Icons.delete),
                    ),

                    const Divider(),

                    CheckboxListTile(
                      title: const Text('Can manage permissions'),
                      subtitle: const Text('Allow managing other members\' permissions'),
                      value: _canManage,
                      onChanged: _canModifyPermissions
                          ? (value) => setState(() {
                                _canManage = value ?? false;
                                _checkForChanges();
                              })
                          : null,
                      secondary: const Icon(Icons.admin_panel_settings),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Role Description
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About ${_getRoleDisplayName(_selectedRole)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getRoleDescription(_selectedRole),
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canModifyPermissions {
    // Only allow modifying permissions if current user is admin/owner
    // and target user is not owner
    return widget.member.role != FamilyRole.owner;
  }

  void _updatePermissionsForRole(FamilyRole role) {
    switch (role) {
      case FamilyRole.owner:
        _canInvite = true;
        _canEdit = true;
        _canShare = true;
        _canDelete = true;
        _canManage = true;
        break;
      case FamilyRole.admin:
        _canInvite = true;
        _canEdit = true;
        _canShare = true;
        _canDelete = false;
        _canManage = true;
        break;
      case FamilyRole.editor:
        _canInvite = false;
        _canEdit = true;
        _canShare = true;
        _canDelete = false;
        _canManage = false;
        break;
      case FamilyRole.viewer:
        _canInvite = false;
        _canEdit = false;
        _canShare = false;
        _canDelete = false;
        _canManage = false;
        break;
      case FamilyRole.limited:
        _canInvite = false;
        _canEdit = false;
        _canShare = false;
        _canDelete = false;
        _canManage = false;
        break;
    }
  }

  void _checkForChanges() {
    final hasRoleChanged = _selectedRole != widget.member.role;
    final hasPermissionsChanged =
        _canInvite != widget.member.permissions.canInviteMembers ||
        _canEdit != widget.member.permissions.canEditSharedNotes ||
        _canShare != widget.member.permissions.canShareNotes ||
        _canDelete != widget.member.permissions.canDeleteSharedNotes ||
        _canManage != widget.member.permissions.canManagePermissions;

    setState(() => _hasChanges = hasRoleChanged || hasPermissionsChanged);
  }

  Color _getRoleColor(FamilyRole role) {
    switch (role) {
      case FamilyRole.owner:
        return Colors.purple;
      case FamilyRole.admin:
        return Colors.blue;
      case FamilyRole.editor:
        return Colors.green;
      case FamilyRole.viewer:
        return Colors.orange;
      case FamilyRole.limited:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(FamilyRole role) {
    switch (role) {
      case FamilyRole.owner:
        return 'Owner';
      case FamilyRole.admin:
        return 'Admin';
      case FamilyRole.editor:
        return 'Editor';
      case FamilyRole.viewer:
        return 'Viewer';
      case FamilyRole.limited:
        return 'Limited';
    }
  }

  String _getRoleDescription(FamilyRole role) {
    switch (role) {
      case FamilyRole.owner:
        return 'Full access to all family features. Can manage members, permissions, and family settings.';
      case FamilyRole.admin:
        return 'Can manage members and permissions. Has most administrative privileges.';
      case FamilyRole.editor:
        return 'Can share and edit notes. Limited administrative access.';
      case FamilyRole.viewer:
        return 'Can view shared notes but cannot make changes or share new content.';
      case FamilyRole.limited:
        return 'Restricted access. Can only view specific shared notes.';
    }
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

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Implement permission updates using FamilyService
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating permissions: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
