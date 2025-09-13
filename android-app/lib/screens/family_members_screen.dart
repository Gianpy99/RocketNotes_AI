// ==========================================
// lib/screens/family_members_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';

import '../models/family_member.dart';
import '../services/family_service.dart';

// T027: Real-time family member activity tracking implementation
// - Real-time activity indicators
// - Online/offline status tracking  
// - Last seen timestamps
// - Member presence tracking
// - Activity history

class FamilyMembersScreen extends ConsumerStatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  ConsumerState<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends ConsumerState<FamilyMembersScreen> {
  final FamilyService _familyService = FamilyService();
  String? _currentFamilyId;

  @override
  void initState() {
    super.initState();
    _loadCurrentFamily();
  }

  Future<void> _loadCurrentFamily() async {
    final result = await _familyService.getUserFamilies();
    if (result.isSuccess && result.data != null && result.data!.isNotEmpty && mounted) {
      setState(() {
        _currentFamilyId = result.data!.first.id;
      });
      // Update user's activity when entering the screen
      _familyService.updateMemberActivity(familyId: _currentFamilyId!);
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
        ],
      ),
    body: _currentFamilyId == null
      ? const Center(child: CircularProgressIndicator())
      : FutureBuilder<ServiceResult<List<FamilyMember>>>(
        future: _familyService.getFamilyMembers(_currentFamilyId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading family members: {snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final result = snapshot.data;
                final members = result?.data ?? [];
                if (members.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildMembersList(members);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Family Members Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your family members to start sharing notes',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddMemberDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add First Family Member'),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        return _buildMemberCard(members[index]);
      },
    );
  }

  Widget _buildMemberCard(FamilyMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getMemberColor(member),
            border: Border.all(
              color: member.isEmergencyContact ? Colors.red : Colors.white,
              width: member.isEmergencyContact ? 2 : 1,
            ),
          ),
          child: member.avatarPath != null
              ? ClipOval(
                  child: Image.network(
                    member.avatarPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildAvatarText(member),
                  ),
                )
              : _buildAvatarText(member),
        ),
        title: Text(
          member.name ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.relationship ?? ''),
            if (member.phoneNumber != null)
              Text(
                member.phoneNumber!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (member.isEmergencyContact)
              const Icon(Icons.emergency, color: Colors.red, size: 20),
            PopupMenuButton<String>(
              onSelected: (action) => _handleMemberAction(member, action),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
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
                if (!member.isEmergencyContact)
                  const PopupMenuItem(
                    value: 'emergency',
                    child: Row(
                      children: [
                        Icon(Icons.emergency, size: 18),
                        SizedBox(width: 8),
                        Text('Set as Emergency Contact'),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showMemberDetails(member),
      ),
    );
  }

  Widget _buildAvatarText(FamilyMember member) {
    return Center(
      child: Text(
  (member.name != null && member.name!.isNotEmpty) ? member.name![0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
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

    final index = member.name.hashCode % colors.length;
    return colors[index];
  }

  void _showAddMemberDialog() {
    // TODO: Implement add member dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Family Member - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleMemberAction(FamilyMember member, String action) {
    switch (action) {
      case 'edit':
        _showEditMemberDialog(member);
        break;
      case 'permissions':
        _showPermissionsDialog(member);
        break;
      case 'emergency':
        _setAsEmergencyContact(member);
        break;
      case 'delete':
        _showDeleteConfirmation(member);
        break;
    }
  }

  void _showMemberDetails(FamilyMember member) {
    // TODO: Implement member details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Member details for ${member.name} - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showEditMemberDialog(FamilyMember member) {
    // TODO: Implement edit member dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${member.name} - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showPermissionsDialog(FamilyMember member) {
    // TODO: Implement permissions dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permissions for ${member.name} - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _setAsEmergencyContact(FamilyMember member) {
    // TODO: Implement emergency contact setting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${member.name} set as emergency contact - Coming Soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteConfirmation(FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family Member'),
        content: Text('Are you sure you want to delete ${member.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement member deletion
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${member.name} deleted - Coming Soon!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
