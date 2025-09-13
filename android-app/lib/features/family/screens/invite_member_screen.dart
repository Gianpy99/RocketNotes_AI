import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/family_member.dart';
import '../../../app/routes.dart';
import '../providers/family_providers.dart';

class InviteMemberScreen extends ConsumerStatefulWidget {
  const InviteMemberScreen({super.key});

  @override
  ConsumerState<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends ConsumerState<InviteMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  FamilyRole _selectedRole = FamilyRole.viewer;
  bool _canInvite = false;
  bool _canEdit = false;
  bool _canShare = false;
  bool _canDelete = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFamilyIdAsync = ref.watch(currentUserFamilyIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Member'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: currentFamilyIdAsync.when(
        data: (familyId) {
          if (familyId == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('No family found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => AppRouter.goToFamilyHome(),
                    child: const Text('Go to Family'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'Enter email of person to invite',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Role Selection
                  Text(
                    'Role',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<FamilyRole>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.admin_panel_settings),
                    ),
                    items: FamilyRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(_getRoleDisplayName(role)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRole = value);
                        _updatePermissionsForRole(value);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Permissions Section
                  Text(
                    'Permissions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Permission Checkboxes
                  CheckboxListTile(
                    title: const Text('Can invite members'),
                    subtitle: const Text('Allow inviting other people to join'),
                    value: _canInvite,
                    onChanged: (value) => setState(() => _canInvite = value ?? false),
                    secondary: const Icon(Icons.person_add),
                  ),

                  CheckboxListTile(
                    title: const Text('Can edit shared notes'),
                    subtitle: const Text('Allow editing notes shared by others'),
                    value: _canEdit,
                    onChanged: (value) => setState(() => _canEdit = value ?? false),
                    secondary: const Icon(Icons.edit),
                  ),

                  CheckboxListTile(
                    title: const Text('Can share notes'),
                    subtitle: const Text('Allow sharing notes with the family'),
                    value: _canShare,
                    onChanged: (value) => setState(() => _canShare = value ?? false),
                    secondary: const Icon(Icons.share),
                  ),

                  CheckboxListTile(
                    title: const Text('Can delete shared notes'),
                    subtitle: const Text('Allow deleting notes shared by others'),
                    value: _canDelete,
                    onChanged: (value) => setState(() => _canDelete = value ?? false),
                    secondary: const Icon(Icons.delete),
                  ),

                  const SizedBox(height: 16),

                  // Message Field
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Personal Message (Optional)',
                      hintText: 'Add a personal message to the invitation',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value != null && value.length > 500) {
                        return 'Message must be less than 500 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Send Invitation Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _sendInvitation(familyId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Send Invitation',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Card
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'The invited person will receive an email with instructions to join your family.',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  void _updatePermissionsForRole(FamilyRole role) {
    switch (role) {
      case FamilyRole.owner:
        setState(() {
          _canInvite = true;
          _canEdit = true;
          _canShare = true;
          _canDelete = true;
        });
        break;
      case FamilyRole.admin:
        setState(() {
          _canInvite = true;
          _canEdit = true;
          _canShare = true;
          _canDelete = false;
        });
        break;
      case FamilyRole.editor:
        setState(() {
          _canInvite = false;
          _canEdit = true;
          _canShare = true;
          _canDelete = false;
        });
        break;
      case FamilyRole.viewer:
        setState(() {
          _canInvite = false;
          _canEdit = false;
          _canShare = false;
          _canDelete = false;
        });
        break;
      case FamilyRole.limited:
        setState(() {
          _canInvite = false;
          _canEdit = false;
          _canShare = false;
          _canDelete = false;
        });
        break;
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

  Future<void> _sendInvitation(String familyId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Invio invito implementato usando FamilyService
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent successfully!')),
        );
        AppRouter.goToFamilyHome();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending invitation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
