import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../app/routes.dart';

class FamilySettingsScreen extends ConsumerStatefulWidget {
  const FamilySettingsScreen({super.key});

  @override
  ConsumerState<FamilySettingsScreen> createState() => _FamilySettingsScreenState();
}

class _FamilySettingsScreenState extends ConsumerState<FamilySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isPublic = false;
  bool _allowInvitations = true;
  bool _requireApproval = false;
  bool _enableNotifications = true;

  @override
  void initState() {
    super.initState();
    // TODO: Load current family settings
    _familyNameController.text = 'My Family'; // Placeholder
    _descriptionController.text = 'A place for our family notes and memories'; // Placeholder
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSettings,
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              Text(
                'Basic Information',
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
                      TextFormField(
                        controller: _familyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Family Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.family_restroom),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Family name is required';
                          }
                          if (value.length < 2) {
                            return 'Family name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          hintText: 'Tell others about your family...',
                        ),
                        validator: (value) {
                          if (value != null && value.length > 500) {
                            return 'Description must be less than 500 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Privacy Settings Section
              Text(
                'Privacy & Access',
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
                      SwitchListTile(
                        title: const Text('Public Family'),
                        subtitle: const Text('Allow others to find and request to join your family'),
                        value: _isPublic,
                        onChanged: (value) => setState(() => _isPublic = value),
                        secondary: const Icon(Icons.public),
                      ),

                      const Divider(),

                      SwitchListTile(
                        title: const Text('Allow Member Invitations'),
                        subtitle: const Text('Members can invite others to join the family'),
                        value: _allowInvitations,
                        onChanged: (value) => setState(() => _allowInvitations = value),
                        secondary: const Icon(Icons.person_add),
                      ),

                      const Divider(),

                      SwitchListTile(
                        title: const Text('Require Approval for New Members'),
                        subtitle: const Text('New members need admin approval before joining'),
                        value: _requireApproval,
                        onChanged: (value) => setState(() => _requireApproval = value),
                        secondary: const Icon(Icons.verified_user),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Notifications Section
              Text(
                'Notifications',
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
                      SwitchListTile(
                        title: const Text('Family Notifications'),
                        subtitle: const Text('Receive notifications about family activities'),
                        value: _enableNotifications,
                        onChanged: (value) => setState(() => _enableNotifications = value),
                        secondary: const Icon(Icons.notifications),
                      ),

                      const Divider(),

                      ListTile(
                        title: const Text('Notification Preferences'),
                        subtitle: const Text('Customize what notifications you receive'),
                        leading: const Icon(Icons.settings),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navigate to notification preferences screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification preferences coming soon!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Danger Zone Section
              Text(
                'Danger Zone',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 16),

              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text(
                          'Leave Family',
                          style: TextStyle(color: Colors.red),
                        ),
                        subtitle: const Text(
                          'Remove yourself from this family. This action cannot be undone.',
                          style: TextStyle(color: Colors.red),
                        ),
                        leading: const Icon(
                          Icons.exit_to_app,
                          color: Colors.red,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.red,
                        ),
                        onTap: _showLeaveFamilyDialog,
                      ),

                      const Divider(color: Colors.red),

                      ListTile(
                        title: const Text(
                          'Delete Family',
                          style: TextStyle(color: Colors.red),
                        ),
                        subtitle: const Text(
                          'Permanently delete this family and all its data. This action cannot be undone.',
                          style: TextStyle(color: Colors.red),
                        ),
                        leading: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.red,
                        ),
                        onTap: _showDeleteFamilyDialog,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Implement settings update using FamilyService
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLeaveFamilyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Family'),
        content: const Text(
          'Are you sure you want to leave this family? You will lose access to all shared notes and family features. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveFamily();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave Family'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFamilyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family'),
        content: const Text(
          'Are you sure you want to delete this family? This will permanently delete all family data, including shared notes, member information, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFamily();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Family'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveFamily() async {
    try {
      // TODO: Implement leave family using FamilyService
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the family')),
        );
        // Navigate back to home or family selection screen
        AppRouter.goToHome();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving family: $e')),
        );
      }
    }
  }

  Future<void> _deleteFamily() async {
    try {
      // TODO: Implement delete family using FamilyService
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family deleted successfully')),
        );
        // Navigate back to home or family selection screen
        AppRouter.goToHome();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting family: $e')),
        );
      }
    }
  }
}
