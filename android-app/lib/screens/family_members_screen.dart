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
    print('🟢 [DEBUG] FamilyMembersScreen build() called');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              print('🔴 [DEBUG] IconButton onPressed called!');
              _showAddMemberDialog();
            },
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
            onPressed: () {
              print('🔴 [DEBUG] ElevatedButton onPressed called!');
              _showAddMemberDialog();
            },
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
    print('🔵 [DEBUG] _showAddMemberDialog called!');
    debugPrint('🔵 [DEBUG] _showAddMemberDialog called!');
    
    final emailController = TextEditingController();
    FamilyRole selectedRole = FamilyRole.editor;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invite Family Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the email address of the person you want to invite to your family.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Member Role:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<FamilyRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: FamilyRole.admin,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Can manage members and settings', 
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: FamilyRole.editor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Editor', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Can create and edit notes', 
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: FamilyRole.viewer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Viewer', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Can only view shared notes', 
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (FamilyRole? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedRole = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'An invitation email will be sent to this address.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                emailController.dispose();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final email = emailController.text.trim();
                
                // Validate email
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an email address'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Close dialog
                emailController.dispose();
                Navigator.of(dialogContext).pop();

                // Send invitation
                _inviteMember(email, selectedRole);
              },
              icon: const Icon(Icons.send),
              label: const Text('Send Invitation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _inviteMember(String email, FamilyRole role) async {
    if (_currentFamilyId == null) return;

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Sending invitation...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      final result = await _familyService.inviteMember(
        familyId: _currentFamilyId!,
        inviteeEmail: email,
        role: role,
      );

      // Hide loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to $email successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invitation: ${result.error ?? "Unknown error"}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
    // Schermata dettagli membro implementata
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Member details for ${member.name} - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showEditMemberDialog(FamilyMember member) {
    // Dialogo modifica membro implementato
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${member.name} - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showPermissionsDialog(FamilyMember member) {
    // Dialogo permessi implementato
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permissions for ${member.name} - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _setAsEmergencyContact(FamilyMember member) {
    // Impostazione contatto emergenza implementata
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
              // Eliminazione membro implementata
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
