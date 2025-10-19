// ==========================================
// lib/presentation/screens/topic_detail_screen.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/topic.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/note_repository.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final Topic topic;

  const TopicDetailScreen({
    super.key,
    required this.topic,
  });

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  late final NoteRepository _noteRepo;
  List<NoteModel> _topicNotes = [];
  List<NoteModel> _allNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _noteRepo = NoteRepository();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final allNotes = await _noteRepo.getAllNotes();
      final topicNotes = allNotes.where((note) => note.topicId == widget.topic.id).toList();
      
      setState(() {
        _allNotes = allNotes;
        _topicNotes = topicNotes;
        _isLoading = false;
      });
    } catch (e) {
      print('[TopicDetail] Error loading notes: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.topic.icon != null) ...[
              Icon(widget.topic.icon, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.topic.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: widget.topic.color.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddNotesDialog,
            tooltip: 'Add Notes to Topic',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Topic info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.topic.color.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: widget.topic.color.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.topic.description != null) ...[
                        Text(
                          widget.topic.description!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Icon(Icons.note, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${_topicNotes.length} notes',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Notes list
                Expanded(
                  child: _topicNotes.isEmpty
                      ? _buildEmptyState()
                      : _buildNotesList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewNoteInTopic,
        icon: const Icon(Icons.note_add),
        label: const Text('New Note'),
        backgroundColor: widget.topic.color,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notes in this topic yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new note or add existing ones',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _createNewNoteInTopic,
                icon: const Icon(Icons.note_add),
                label: const Text('New Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.topic.color,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _showAddNotesDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Existing'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      itemCount: _topicNotes.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final note = _topicNotes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.topic.color.withOpacity(0.2),
              child: Icon(Icons.note, color: widget.topic.color),
            ),
            title: Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDate(note.updatedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'open',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new),
                      SizedBox(width: 8),
                      Text('Open Note'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove from Topic', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleNoteAction(value, note),
            ),
            onTap: () => _openNote(note),
          ),
        );
      },
    );
  }

  Future<void> _showAddNotesDialog() async {
    // Get notes that are NOT already in this topic
    final availableNotes = _allNotes
        .where((note) => note.topicId != widget.topic.id)
        .toList();

    if (availableNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other notes available. Create a new note first!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final selectedNotes = <NoteModel>[];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Notes to Topic'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select notes to add to "${widget.topic.name}"',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableNotes.length,
                    itemBuilder: (context, index) {
                      final note = availableNotes[index];
                      final isSelected = selectedNotes.contains(note);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedNotes.add(note);
                            } else {
                              selectedNotes.remove(note);
                            }
                          });
                        },
                        title: Text(
                          note.title.isEmpty ? 'Untitled' : note.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          note.content.isEmpty
                              ? 'No content'
                              : note.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        secondary: Icon(
                          Icons.note,
                          color: widget.topic.color,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedNotes.isEmpty
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      await _addNotesToTopic(selectedNotes);
                    },
              child: Text('Add ${selectedNotes.length} Note(s)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNotesToTopic(List<NoteModel> notes) async {
    try {
      for (final note in notes) {
        final updatedNote = note.copyWith(topicId: widget.topic.id);
        await _noteRepo.saveNote(updatedNote);
        print('[TopicDetail] Added note ${note.id} to topic ${widget.topic.id}');
      }

      await _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${notes.length} note(s) to ${widget.topic.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[TopicDetail] Error adding notes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleNoteAction(String action, NoteModel note) async {
    switch (action) {
      case 'open':
        _openNote(note);
        break;
      case 'remove':
        await _removeNoteFromTopic(note);
        break;
    }
  }

  Future<void> _removeNoteFromTopic(NoteModel note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Note'),
        content: Text(
          'Remove "${note.title.isEmpty ? 'this note' : note.title}" from "${widget.topic.name}"?\n\nThe note will not be deleted, just unlinked from this topic.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final updatedNote = note.copyWith(topicId: null);
        await _noteRepo.saveNote(updatedNote);
        await _loadNotes();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note removed from topic'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('[TopicDetail] Error removing note: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _openNote(NoteModel note) {
    // Navigate to note editor
    context.push('/note-editor', extra: note);
  }

  Future<void> _createNewNoteInTopic() async {
    // Create a new note with this topic pre-assigned
    final newNote = NoteModel.create(
      mode: 'personal', // default mode
      title: '',
      content: '',
    ).copyWith(topicId: widget.topic.id);
    
    // Navigate to note editor
    context.push('/note-editor', extra: newNote);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
