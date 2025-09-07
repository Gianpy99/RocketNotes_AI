import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/note_permission.dart';
import '../providers/shared_notes_providers.dart';

class NoteSharingScreen extends ConsumerStatefulWidget {
  final String? noteId; // Optional: if sharing a specific note

  const NoteSharingScreen({
    super.key,
    this.noteId,
  });

  @override
  ConsumerState<NoteSharingScreen> createState() => _NoteSharingScreenState();
}

class _NoteSharingScreenState extends ConsumerState<NoteSharingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _requiresApproval = false;
  bool _allowCollaboration = false;
  DateTime? _expirationDate;

  NotePermission? _selectedPermission;

  // Permission options
  final List<NotePermission> _permissionOptions = [
    NotePermission.readOnly(
      id: 'temp-readonly',
      sharedNoteId: 'temp',
      userId: 'temp',
      familyMemberId: 'temp',
      grantedBy: 'temp',
    ),
    NotePermission.editor(
      id: 'temp-editor',
      sharedNoteId: 'temp',
      userId: 'temp',
      familyMemberId: 'temp',
      grantedBy: 'temp',
    ),
    NotePermission.fullAccess(
      id: 'temp-full',
      sharedNoteId: 'temp',
      userId: 'temp',
      familyMemberId: 'temp',
      grantedBy: 'temp',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedPermission = _permissionOptions[0]; // Default to read-only

    // If editing existing shared note, load its data
    if (widget.noteId != null) {
      _loadExistingNoteData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingNoteData() async {
    // TODO: Load existing shared note data if editing
    // Implementation: Check if widget.noteId is provided and load existing shared note data
    // Query shared notes repository to get current sharing settings, permissions, and expiration
    // Populate form fields with existing data for editing mode
  }

  @override
  Widget build(BuildContext context) {
    final shareNoteAsync = ref.watch(shareNoteProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId != null ? 'Edit Sharing' : 'Share Note'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (shareNoteAsync.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            TextButton(
              onPressed: _shareNote,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Share'),
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
              // Note Information Section
              Text(
                'Note Information',
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
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Note Title',
                          hintText: 'Enter a title for the shared note',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          if (value.length < 3) {
                            return 'Title must be at least 3 characters';
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
                          hintText: 'Add a description to help others understand this note',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
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

              // Permissions Section
              Text(
                'Sharing Permissions',
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
                      const Text(
                        'Select the permission level for family members:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),

                      const SizedBox(height: 16),

                      ..._permissionOptions.map((permission) {
                        return RadioMenuButton<NotePermission>(
                          value: permission,
                          groupValue: _selectedPermission,
                          onChanged: (value) {
                            setState(() => _selectedPermission = value);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                permission.permissionLevel,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                _getPermissionDescription(permission),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const Divider(),

                      SwitchListTile(
                        title: const Text('Allow Collaboration'),
                        subtitle: const Text('Let others edit this note in real-time'),
                        value: _allowCollaboration,
                        onChanged: (value) => setState(() => _allowCollaboration = value),
                        secondary: const Icon(Icons.group_work),
                      ),

                      const Divider(),

                      SwitchListTile(
                        title: const Text('Require Approval'),
                        subtitle: const Text('Family admin must approve before sharing'),
                        value: _requiresApproval,
                        onChanged: (value) => setState(() => _requiresApproval = value),
                        secondary: const Icon(Icons.verified_user),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Expiration Section
              Text(
                'Expiration (Optional)',
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
                      ListTile(
                        title: const Text('Set Expiration Date'),
                        subtitle: Text(
                          _expirationDate != null
                              ? 'Expires on ${_formatDate(_expirationDate!)}'
                              : 'No expiration date set',
                        ),
                        leading: const Icon(Icons.calendar_today),
                        trailing: _expirationDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _expirationDate = null),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _selectExpirationDate,
                      ),

                      if (_expirationDate != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This note will automatically become inaccessible after the expiration date.',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Preview Section
              Text(
                'Sharing Preview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.share,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Note will be shared with:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titleController.text.isEmpty
                                  ? 'Note Title'
                                  : _titleController.text,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            if (_descriptionController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _descriptionController.text,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _selectedPermission?.permissionLevel ?? 'Read Only',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                if (_allowCollaboration) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.group_work,
                                          size: 12,
                                          color: Colors.green[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Collaborative',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            if (_expirationDate != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Expires: ${_formatDate(_expirationDate!)}',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
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

  String _getPermissionDescription(NotePermission permission) {
    if (permission.canEdit && permission.canShare) {
      return 'Full access: view, edit, comment, share, and manage the note';
    } else if (permission.canEdit) {
      return 'Can view, edit, and comment on the note';
    } else if (permission.canComment) {
      return 'Can view and comment on the note';
    } else {
      return 'Can only view the note';
    }
  }

  Future<void> _selectExpirationDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() => _expirationDate = pickedDate);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _shareNote() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPermission == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select sharing permissions')),
      );
      return;
    }

    try {
      // TODO: Implement actual note sharing
      // Implementation: Create shared note record in Firestore with selected permissions
      // Generate unique share ID and store in shared_notes collection
      // Send notifications to selected family members via Firebase Cloud Messaging
      // Update note's sharing status and permissions in the main notes collection
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note shared successfully!')),
        );
        context.pop(); // Go back to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing note: $e')),
        );
      }
    }
  }
}
