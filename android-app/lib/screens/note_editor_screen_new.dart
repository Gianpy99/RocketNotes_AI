// Simple Note Editor Screen
// A lightweight editor kept for older navigation paths. Uses the shared notes provider API.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/note_model.dart';
import '../ui/widgets/note_editor/tag_input.dart';
import '../presentation/providers/app_providers.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final NoteModel? note;
  final String? initialAppMode; // optional immediate fallback

  const NoteEditorScreen({super.key, this.note, this.initialAppMode});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  List<String> _tags = [];
  String _selectedMode = 'personal';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tags = List.from(widget.note?.tags ?? []);
    // Prefer immediate fallback, then existing note mode, then provider
    try {
      _selectedMode = widget.note?.mode ?? widget.initialAppMode ?? ref.read(appModeProvider);
      debugPrint('[SIMPLE EDITOR] 📝 Initialized with mode: $_selectedMode (note: ${widget.note?.mode}, initial: ${widget.initialAppMode})');
    } catch (_) {
      _selectedMode = widget.note?.mode ?? widget.initialAppMode ?? 'personal';
      debugPrint('[SIMPLE EDITOR] ⚠️ Fallback mode: $_selectedMode');
    }
    _isEditing = widget.note != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci almeno un titolo o contenuto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newNote = NoteModel(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      tags: _tags,
      mode: _selectedMode,
      attachments: [],
      isFavorite: widget.note?.isFavorite ?? false,
      priority: widget.note?.priority ?? 0,
    );

    debugPrint('[SIMPLE EDITOR] 💾 Saving note with mode: $_selectedMode');

    try {
      final noteProvider = ref.read(notesProvider.notifier);
      await noteProvider.saveNote(newNote);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nota salvata con successo'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvare la nota: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Nota'),
        content: const Text('Sei sicuro di voler eliminare questa nota?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Elimina', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final noteProvider = ref.read(notesProvider.notifier);
        await noteProvider.deleteNote(widget.note!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nota eliminata'), backgroundColor: Colors.orange),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore nell\'eliminare la nota: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _shareNote() async {
    final title = _titleController.text.trim().isEmpty ? 'Nota senza titolo' : _titleController.text.trim();
    final content = _contentController.text.trim();
    final tags = _tags.isNotEmpty ? '\n\nTag: ${_tags.join(', ')}' : '';
    final shareText = '$title\n\n$content$tags';

    try {
      await Share.share(shareText, subject: title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella condivisione: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica Nota' : 'Nuova Nota'),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteNote),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'save':
                  _saveNote();
                  break;
                case 'share':
                  _shareNote();
                  break;
                case 'delete':
                  if (_isEditing) _deleteNote();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'save', child: ListTile(leading: Icon(Icons.save), title: Text('Salva'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share), title: Text('Condividi'), contentPadding: EdgeInsets.zero)),
              if (_isEditing) const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Elimina', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo di Nota', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: RadioListTile<String>(title: const Text('Personale'), value: 'personal', groupValue: _selectedMode, onChanged: (v) => setState(() => _selectedMode = v ?? 'personal'), dense: true, contentPadding: EdgeInsets.zero)),
                        Expanded(child: RadioListTile<String>(title: const Text('Lavoro'), value: 'work', groupValue: _selectedMode, onChanged: (v) => setState(() => _selectedMode = v ?? 'work'), dense: true, contentPadding: EdgeInsets.zero)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titolo della Nota', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)), textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 16),
            TextField(controller: _contentController, decoration: const InputDecoration(labelText: 'Contenuto della Nota', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes), alignLabelWithHint: true), maxLines: 8, textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 16),
            const Text('Tag (separati da virgola)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TagInput(tags: _tags, onTagsChanged: (newTags) => setState(() => _tags = newTags), noteContent: _contentController.text),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _saveNote, icon: const Icon(Icons.save), label: Text(_isEditing ? 'Aggiorna Nota' : 'Salva Nota')),
    );
  }
}
