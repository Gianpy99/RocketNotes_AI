// lib/presentation/screens/note_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/note_model.dart';
import '../providers/app_providers.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  
  const NoteEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocus;
  late FocusNode _contentFocus;
  
  NoteModel? currentNote;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _titleFocus = FocusNode();
    _contentFocus = FocusNode();
    
    if (widget.noteId != null) {
      _loadNote();
    } else {
      // Focus on title for new notes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocus.requestFocus();
      });
    }
  }

  Future<void> _loadNote() async {
    setState(() => isLoading = true);
    try {
      final repository = ref.read(noteRepositoryProvider);
      final note = await repository.getNoteById(widget.noteId!);
      if (note != null) {
        setState(() {
          currentNote = note;
          _titleController.text = note.title;
          _contentController.text = note.content;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading note: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      return;
    }

    final currentMode = ref.read(appModeProvider);
    final now = DateTime.now();
    
    final note = currentNote?.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      updatedAt: now,
    ) ?? NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      content: _contentController.text,
      mode: currentMode,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(notesProvider.notifier).saveNote(note);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId != null ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
          if (widget.noteId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              decoration: const InputDecoration(
                hintText: 'Note title...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              style: Theme.of(context).textTheme.titleLarge,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _contentFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                focusNode: _contentFocus,
                decoration: const InputDecoration(
                  hintText: 'Start writing your note...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(notesProvider.notifier).deleteNote(widget.noteId!);
              if (mounted) {
                context.pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
