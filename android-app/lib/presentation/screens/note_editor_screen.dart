// lib/presentation/screens/note_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/note_model.dart';
import '../providers/app_providers.dart';
import '../widgets/tag_input_field.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  
  List<String> _tags = [];
  NoteModel? _currentNote;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadNote();
    _setupChangeListeners();
  }

  void _setupChangeListeners() {
    _titleController.addListener(() {
      if (!_hasUnsavedChanges) {
        setState(() {
          _hasUnsavedChanges = true;
        });
      }
    });

    _contentController.addListener(() {
      if (!_hasUnsavedChanges) {
        setState(() {
          _hasUnsavedChanges = true;
        });
      }
    });
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      final note = await ref.read(notesProvider.notifier).getNoteById(widget.noteId!);
      if (note != null) {
        setState(() {
          _currentNote = note;
          _titleController.text = note.title;
          _contentController.text = note.content;
          _tags = List.from(note.tags);
          _isLoading = false;
        });
        return;
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      return;
    }

    final currentMode = ref.read(appModeProvider);
    final now = DateTime.now();

    final note = _currentNote?.copyWith(
      title: _titleController.text.trim().isEmpty 
          ? 'Untitled Note' 
          : _titleController.text.trim(),
      content: _contentController.text,
      updatedAt: now,
      tags: _tags,
    ) ?? NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim().isEmpty 
          ? 'Untitled Note' 
          : _titleController.text.trim(),
      content: _contentController.text,
      mode: currentMode,
      createdAt: now,
      updatedAt: now,
      tags: _tags,
    );

    await ref.read(notesProvider.notifier).saveNote(note);
    
    setState(() {
      _hasUnsavedChanges = false;
      _currentNote = note;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () async {
              await _saveNote();
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        _onWillPop().then((shouldPop) {
          if (shouldPop && context.mounted) {
            context.pop();
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentNote == null ? 'New Note' : 'Edit Note'),
          actions: [
            if (_hasUnsavedChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveNote,
                tooltip: 'Save',
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'save':
                    _saveNote();
                    break;
                  case 'delete':
                    if (_currentNote != null) {
                      _showDeleteDialog();
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'save',
                  child: ListTile(
                    leading: Icon(Icons.save),
                    title: Text('Save'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (_currentNote != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Mode Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    ref.watch(appModeProvider) == 'work' ? Icons.work : Icons.home,
                    size: 16,
                    color: ref.watch(appModeProvider) == 'work'
                        ? AppColors.workBlue
                        : AppColors.personalGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ref.watch(appModeProvider).toUpperCase()} MODE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ref.watch(appModeProvider) == 'work'
                          ? AppColors.workBlue
                          : AppColors.personalGreen,
                    ),
                  ),
                  const Spacer(),
                  if (_hasUnsavedChanges)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Unsaved',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Title Field
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Note title...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _contentFocusNode.requestFocus(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tags Input
                    TagInputField(
                      tags: _tags,
                      onTagsChanged: (newTags) {
                        setState(() {
                          _tags = newTags;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // OCR Tools Row
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showOCRPanel,
                          icon: const Icon(Icons.text_fields),
                          label: const Text('Extract Text'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _quickOCR,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Quick OCR'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Content Field
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                          hintText: 'Start writing your note...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement AI features
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('AI features coming soon!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('AI Enhance'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _hasUnsavedChanges ? _saveNote : null,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Note'),
                          ),
                        ),
                      ],
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

  void _showOCRPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'OCR Text Extraction',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _selectImageForOCR,
                      icon: const Icon(Icons.image),
                      label: const Text('Select Image for OCR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select an image to extract text from it and add to your note.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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
  }

  void _selectImageForOCR() async {
    Navigator.of(context).pop(); // Chiudi il modal
    
    // Qui implementeremo la selezione immagine e OCR
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('Image selection and OCR processing will be implemented next.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _quickOCR() async {
    // Implementazione rapida per catturare e processare immagine
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick OCR'),
        content: const Text('Quick OCR feature will allow instant text extraction from camera or clipboard.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showOCRPanel();
            },
            child: const Text('Open OCR Panel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    if (_currentNote == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${_currentNote!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(notesProvider.notifier).deleteNote(_currentNote!.id);
              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog
                context.pop(); // Go back to previous screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note deleted'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
