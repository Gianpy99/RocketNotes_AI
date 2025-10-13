import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/family.dart';
import '../providers/family_providers.dart';

class CreateFamilyScreen extends ConsumerStatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  ConsumerState<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends ConsumerState<CreateFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _allowInvitations = true;
  bool _requireApproval = false;
  int _maxMembers = 10;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Family'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Family Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Family Name',
                  hintText: 'Enter your family name',
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
                  if (value.length > 50) {
                    return 'Family name must be less than 50 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Family Description (Optional)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Tell others about your family',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.length > 200) {
                    return 'Description must be less than 200 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Settings Section
              Text(
                'Family Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Allow Invitations
              SwitchListTile(
                title: const Text('Allow Member Invitations'),
                subtitle: const Text('Family members can invite others to join'),
                value: _allowInvitations,
                onChanged: (value) => setState(() => _allowInvitations = value),
                secondary: const Icon(Icons.person_add),
              ),

              // Require Approval
              SwitchListTile(
                title: const Text('Require Approval for New Members'),
                subtitle: const Text('New members need approval before joining'),
                value: _requireApproval,
                onChanged: (value) => setState(() => _requireApproval = value),
                secondary: const Icon(Icons.check_circle),
              ),

              const SizedBox(height: 16),

              // Max Members
              Text(
                'Maximum Members: $_maxMembers',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              Slider(
                value: _maxMembers.toDouble(),
                min: 2,
                max: 50,
                divisions: 24,
                label: _maxMembers.toString(),
                onChanged: (value) => setState(() => _maxMembers = value.toInt()),
              ),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createFamily,
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
                          'Create Family',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Text
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
                          'As the family creator, you will be the owner and can manage all family settings and members.',
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
      ),
    );
  }

  Future<void> _createFamily() async {
    debugPrint('🚀 [CREATE FAMILY] Starting family creation...');
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ [CREATE FAMILY] Form validation failed');
      return;
    }

    debugPrint('✅ [CREATE FAMILY] Form validated successfully');
    setState(() => _isLoading = true);

    try {
      debugPrint('📋 [CREATE FAMILY] Creating FamilySettings...');
      // Create FamilySettings from form data
      final settings = FamilySettings(
        allowPublicSharing: true,
        requireApprovalForSharing: _requireApproval,
        maxMembers: _maxMembers,
        defaultNoteExpiration: const Duration(days: 30),
        enableRealTimeSync: true,
        notifications: const NotificationPreferences(
          emailInvitations: true,
          pushNotifications: true,
          activityDigest: ActivityDigestFrequency.weekly,
        ),
      );
      debugPrint('✅ [CREATE FAMILY] FamilySettings created');

      debugPrint('🔍 [CREATE FAMILY] Getting familyServiceProvider...');
      // Create the family using the service
      final familyService = ref.read(familyServiceProvider);
      debugPrint('✅ [CREATE FAMILY] FamilyService obtained: ${familyService.runtimeType}');
      
      debugPrint('🏗️ [CREATE FAMILY] Calling createFamily with name: "${_nameController.text.trim()}"');
      final family = await familyService.createFamily(
        name: _nameController.text.trim(),
        settings: settings,
      );
      debugPrint('✅ [CREATE FAMILY] Family created successfully: ${family.id}');

      if (mounted) {
        debugPrint('🔄 [CREATE FAMILY] Invalidating family providers to refresh data');
        // Invalidate providers to refresh the family list
        ref.invalidate(currentUserFamilyIdProvider);
        ref.invalidate(currentFamilyProvider);
        ref.invalidate(familyMembersProvider);
        
        debugPrint('✅ [CREATE FAMILY] Showing success message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Family "${family.name}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        debugPrint('↩️ [CREATE FAMILY] Navigating back');
        // Navigate back to family home
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [CREATE FAMILY] Error creating family: $e');
      debugPrint('📚 [CREATE FAMILY] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating family: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        debugPrint('🏁 [CREATE FAMILY] Setting isLoading to false');
        setState(() => _isLoading = false);
      }
    }
  }
}
