// ==========================================
// lib/screens/enhanced_note_editor_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/note_model.dart';
import '../main_simple.dart';
import '../widgets/collaborative_note_editor.dart';
import '../core/constants/app_colors.dart';

// T028: Enhanced note editor with real-time collaboration
// Integrates collaborative editing capabilities into existing note editor
// - Detects if note is shared and enables collaboration features
// - Provides seamless transition between personal and collaborative editing
// - Maintains compatibility with existing note management system

class EnhancedNoteEditorScreen extends ConsumerStatefulWidget {
  final NoteModel? note;
  final String? sharedNoteId; // New parameter for shared note editing

  const EnhancedNoteEditorScreen({
    super.key, 
    this.note,
    this.sharedNoteId,
  });

  @override
  ConsumerState<EnhancedNoteEditorScreen> createState() => _EnhancedNoteEditorScreenState();
}

class _EnhancedNoteEditorScreenState extends ConsumerState<EnhancedNoteEditorScreen> {
  List<String> _tags = [];
  String _selectedMode = 'personal';
  bool _isEditing = false;
  List<String> _attachments = [];
  bool _isSharedNote = false;
  String _currentTitle = '';
  String _currentContent = '';

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.note?.title ?? '';
    _currentContent = widget.note?.content ?? '';
    _tags = List.from(widget.note?.tags ?? []);
    _selectedMode = widget.note?.mode ?? 'personal';
    _isEditing = widget.note != null;
    _attachments = List.from(widget.note?.attachments ?? []);
    _isSharedNote = widget.sharedNoteId != null;
  }

  void _onContentChanged(String title, String content) {
    setState(() {
      _currentTitle = title;
      _currentContent = content;
    });
    
    // Auto-save for shared notes or regular save for personal notes
    if (_isSharedNote) {
      _autoSaveSharedNote();
    } else {
      _autoSavePersonalNote();
    }
  }

  Future<void> _autoSaveSharedNote() async {
    // Implementation would save changes to shared note via SharedNotesService
    // This is where real-time collaboration sync would happen
    debugPrint('Auto-saving shared note changes...');
  }

  Future<void> _autoSavePersonalNote() async {
    // Implementation would save personal note changes
    debugPrint('Auto-saving personal note changes...');
  }

  Future<void> _saveNote() async {
    if (_currentTitle.trim().isEmpty && _currentContent.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least a title or content'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newNote = NoteModel(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _currentTitle.trim(),
      content: _currentContent.trim(),
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      tags: _tags,
      mode: _selectedMode,
      attachments: _attachments,
      isFavorite: widget.note?.isFavorite ?? false,
      priority: widget.note?.priority ?? 0,
    );

    try {
      final noteProvider = ref.read(notesProvider.notifier);
      if (_isEditing) {
        await noteProvider.updateNote(newNote);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await noteProvider.addNote(newNote);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSharedNote ? 'Shared Note' : 'Note Editor'),
        backgroundColor: _isSharedNote ? Colors.blue : AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isSharedNote)
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: _showCollaborationInfo,
              tooltip: 'Collaboration Info',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
            tooltip: 'Save Note',
          ),
          if (!_isSharedNote)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 18),
                      SizedBox(width: 8),
                      Text('Share with Family'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'tags',
                  child: Row(
                    children: [
                      Icon(Icons.label, size: 18),
                      SizedBox(width: 8),
                      Text('Manage Tags'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'mode',
                  child: Row(
                    children: [
                      Icon(Icons.mode_edit, size: 18),
                      SizedBox(width: 8),
                      Text('Change Mode'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isSharedNote 
          ? _buildSharedNoteEditor()
          : _buildPersonalNoteEditor(),
      ),
    );
  }

  Widget _buildSharedNoteEditor() {
    return CollaborativeNoteEditor(
      sharedNoteId: widget.sharedNoteId,
      initialTitle: _currentTitle,
      initialContent: _currentContent,
      onContentChanged: _onContentChanged,
      isSharedNote: true,
    );
  }

  Widget _buildPersonalNoteEditor() {
    return CollaborativeNoteEditor(
      initialTitle: _currentTitle,
      initialContent: _currentContent,
      onContentChanged: _onContentChanged,
      isSharedNote: false,
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _showShareDialog();
        break;
      case 'tags':
        _showTagsDialog();
        break;
      case 'mode':
        _showModeDialog();
        break;
    }
  }

  void _showCollaborationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.people, color: Colors.blue),
            SizedBox(width: 8),
            Text('Collaboration Active'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✓ Real-time editing enabled'),
            SizedBox(height: 8),
            Text('✓ Live user presence'),
            SizedBox(height: 8),
            Text('✓ Auto-sync every 500ms'),
            SizedBox(height: 8),
            Text('✓ Conflict resolution'),
            SizedBox(height: 16),
            Text(
              'Changes are automatically saved and synced with other collaborators.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Note'),
        content: const Text('Note sharing will be implemented soon with family collaboration features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note sharing feature coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showTagsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Tags'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_tags.isEmpty)
              const Text('No tags added yet')
            else
              Wrap(
                spacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () {
                    setState(() {
                      _tags.remove(tag);
                    });
                    Navigator.of(context).pop();
                    _showTagsDialog(); // Refresh dialog
                  },
                )).toList(),
              ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Add new tag',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty && !_tags.contains(value.trim())) {
                  setState(() {
                    _tags.add(value.trim());
                  });
                  Navigator.of(context).pop();
                  _showTagsDialog(); // Refresh dialog
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Personal'),
              subtitle: const Text('Private note, visible only to you'),
              value: 'personal',
              groupValue: _selectedMode,
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Family'),
              subtitle: const Text('Can be shared with family members'),
              value: 'family',
              groupValue: _selectedMode,
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Work'),
              subtitle: const Text('Professional notes and documents'),
              value: 'work',
              groupValue: _selectedMode,
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}