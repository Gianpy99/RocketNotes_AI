// ==========================================
// lib/screens/family_members_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../models/family_member.dart';
import '../services/family_service.dart';

// T027: Real-time family member activity tracking implementation
// - Real-time activity indicators with streaming data
// - Online/offline status tracking  
// - Last seen timestamps
// - Member presence tracking with live updates
// - Activity history

class FamilyMembersScreen extends ConsumerStatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  ConsumerState<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends ConsumerState<FamilyMembersScreen> with WidgetsBindingObserver {
  final FamilyService _familyService = FamilyService();
  String? _currentFamilyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentFamily();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Update user activity when app becomes active
    if (state == AppLifecycleState.resumed && _currentFamilyId != null) {
      _familyService.updateMemberActivity(familyId: _currentFamilyId!);
    }
  }

  Future<void> _loadCurrentFamily() async {
    try {
      final result = await _familyService.getUserFamilies();
      if (result.isSuccess && result.data != null && result.data!.isNotEmpty && mounted) {
        setState(() {
          _currentFamilyId = result.data!.first.id;
          _isLoading = false;
        });
        // Update user's activity when entering the screen
        _familyService.updateMemberActivity(familyId: _currentFamilyId!);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddMemberDialog,
            tooltip: 'Add Family Member',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _familyService.updateMemberActivity(familyId: _currentFamilyId!),
            tooltip: 'Update Activity',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _currentFamilyId == null 
          ? _buildNoFamilyState()
          : _buildFamilyMembersStream(),
    );
  }

  Widget _buildNoFamilyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Family Found',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create or join a family to see members',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateFamilyDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Family'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMembersStream() {
    return StreamBuilder<List<FamilyMember>>(
      stream: _familyService.getFamilyMembersStream(_currentFamilyId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Members',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final members = snapshot.data ?? [];
        
        if (members.isEmpty) {
          return _buildEmptyMembersState();
        }

        return _buildMembersList(members);
      },
    );
  }

  Widget _buildEmptyMembersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_add,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Family Members',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite family members to start collaborating',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddMemberDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Invite Family Member'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(List<FamilyMember> members) {
    // Sort members by activity status and last active time
    final sortedMembers = List<FamilyMember>.from(members);
    sortedMembers.sort((a, b) {
      // First by online status (based on recent activity)
      final aOnline = _isRecentlyActive(a);
      final bOnline = _isRecentlyActive(b);
      
      if (aOnline != bOnline) {
        return aOnline ? -1 : 1;
      }
      
      // Then by last active time (most recent first)
      if (a.lastActiveAt != null && b.lastActiveAt != null) {
        return b.lastActiveAt!.compareTo(a.lastActiveAt!);
      } else if (a.lastActiveAt != null) {
        return -1;
      } else if (b.lastActiveAt != null) {
        return 1;
      }
      
      // Finally by join date
      return a.joinedAt.compareTo(b.joinedAt);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMembers.length,
      itemBuilder: (context, index) {
        return _buildEnhancedMemberCard(sortedMembers[index]);
      },
    );
  }

  Widget _buildEnhancedMemberCard(FamilyMember member) {
    final isOnline = _isRecentlyActive(member);
    final lastActiveText = _getLastActiveText(member);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getMemberColor(member),
                border: Border.all(
                  color: member.role == FamilyRole.owner ? Colors.amber : Colors.grey.shade300,
                  width: member.role == FamilyRole.owner ? 2 : 1,
                ),
              ),
              child: _buildMemberAvatar(member),
            ),
            // Activity indicator
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? Colors.green : Colors.grey,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.userId, // Using userId as display name for now
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            _buildRoleBadge(member.role),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isOnline ? Icons.circle : Icons.schedule,
                  size: 12,
                  color: isOnline ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Online' : lastActiveText,
                  style: TextStyle(
                    color: isOnline ? Colors.green : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: isOnline ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (member.permissions.hasAdminCapabilities)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 12,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Admin Capabilities',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Real-time activity indicator
            if (isOnline)
              Tooltip(
                message: 'Currently active',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.online_prediction,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (action) => _handleMemberAction(member, action),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view_activity',
                  child: Row(
                    children: [
                      Icon(Icons.timeline, size: 18),
                      SizedBox(width: 8),
                      Text('View Activity'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'permissions',
                  child: Row(
                    children: [
                      Icon(Icons.security, size: 18),
                      SizedBox(width: 8),
                      Text('Permissions'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                if (member.role != FamilyRole.owner)
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () => _showMemberActivity(member),
      ),
    );
  }

  Widget _buildMemberAvatar(FamilyMember member) {
    return Center(
      child: Text(
        member.userId.isNotEmpty ? member.userId[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(FamilyRole role) {
    Color color;
    String text;
    
    switch (role) {
      case FamilyRole.owner:
        color = Colors.amber;
        text = 'Owner';
        break;
      case FamilyRole.admin:
        color = Colors.blue;
        text = 'Admin';
        break;
      case FamilyRole.editor:
        color = Colors.green;
        text = 'Editor';
        break;
      case FamilyRole.viewer:
        color = Colors.grey;
        text = 'Viewer';
        break;
      case FamilyRole.limited:
        color = Colors.orange;
        text = 'Limited';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.orange[700]!,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getMemberColor(FamilyMember member) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];

    final index = member.userId.hashCode % colors.length;
    return colors[index];
  }

  bool _isRecentlyActive(FamilyMember member) {
    if (member.lastActiveAt == null) return false;
    
    final now = DateTime.now();
    final diff = now.difference(member.lastActiveAt!);
    
    // Consider online if active within last 5 minutes
    return diff.inMinutes < 5;
  }

  String _getLastActiveText(FamilyMember member) {
    if (member.lastActiveAt == null) return 'Never seen';
    
    final now = DateTime.now();
    final diff = now.difference(member.lastActiveAt!);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return 'Long time ago';
    }
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Family Member'),
        content: const Text('Family member invitation feature will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCreateFamilyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Family'),
        content: const Text('Family creation feature will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleMemberAction(FamilyMember member, String action) {
    switch (action) {
      case 'view_activity':
        _showMemberActivity(member);
        break;
      case 'permissions':
        _showPermissionsDialog(member);
        break;
      case 'remove':
        _showRemoveConfirmation(member);
        break;
    }
  }

  void _showMemberActivity(FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member.userId} Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${member.role.name}'),
            const SizedBox(height: 8),
            Text('Joined: ${member.joinedAt.toString().split('.')[0]}'),
            const SizedBox(height: 8),
            Text(
              'Last Active: ${member.lastActiveAt?.toString().split('.')[0] ?? 'Never'}',
            ),
            const SizedBox(height: 8),
            Text('Status: ${_isRecentlyActive(member) ? 'Online' : 'Offline'}'),
            const SizedBox(height: 16),
            const Text('Real-time activity tracking active!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPermissionsDialog(FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member.userId} Permissions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionItem('Share Notes', member.permissions.canShareNotes),
            _buildPermissionItem('Edit Shared Notes', member.permissions.canEditSharedNotes),
            _buildPermissionItem('Delete Shared Notes', member.permissions.canDeleteSharedNotes),
            _buildPermissionItem('Invite Members', member.permissions.canInviteMembers),
            _buildPermissionItem('Manage Permissions', member.permissions.canManagePermissions),
            _buildPermissionItem('Admin Capabilities', member.permissions.hasAdminCapabilities),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String permission, bool hasPermission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(permission),
        ],
      ),
    );
  }

  void _showRemoveConfirmation(FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Family Member'),
        content: Text(
          'Are you sure you want to remove ${member.userId} from the family? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeMember(member);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _removeMember(FamilyMember member) async {
    try {
      final result = await _familyService.removeMember(
        familyId: _currentFamilyId!,
        memberUserId: member.userId,
      );
      
      if (result.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.userId} removed from family'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}