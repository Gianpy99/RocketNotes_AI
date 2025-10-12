// ==========================================
// lib/screens/audio_note_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/widgets/audio_note_recorder.dart';
import '../data/models/note_model.dart';
import '../presentation/providers/app_providers_simple.dart';

/// Screen for creating audio notes with AI transcription and translation
class AudioNoteScreen extends ConsumerStatefulWidget {
  const AudioNoteScreen({super.key});

  @override
  ConsumerState<AudioNoteScreen> createState() => _AudioNoteScreenState();
}

class _AudioNoteScreenState extends ConsumerState<AudioNoteScreen> {
  String? _transcription;
  String? _translation;
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  String _mode = 'personal';

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Audio Note'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_transcription != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
              tooltip: 'Save Note',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Smart Audio Transcription',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• AI-powered transcription with OpenAI Whisper or Gemini\n'
                      '• Automatic language detection\n'
                      '• Smart translation only when needed\n'
                      '• Cost tracking and optimization',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Audio recorder widget
            AudioNoteRecorder(
              targetLanguage: 'it', // Can be made configurable
              onTranscriptionComplete: (transcription, translation) {
                setState(() {
                  _transcription = transcription;
                  _translation = translation;
                });
                
                // Auto-generate title from first words
                final words = transcription.split(' ').take(5).join(' ');
                _titleController.text = words.length > 30 
                    ? '${words.substring(0, 27)}...' 
                    : words;
              },
            ),

            if (_transcription != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Note details form
              Text(
                'Note Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Title field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),

              const SizedBox(height: 16),

              // Mode selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'work',
                    label: Text('Work'),
                    icon: Icon(Icons.work),
                  ),
                  ButtonSegment(
                    value: 'personal',
                    label: Text('Personal'),
                    icon: Icon(Icons.person),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _mode = newSelection.first;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Tags field
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                  hintText: 'meeting, ideas, todo',
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              ElevatedButton.icon(
                onPressed: _saveNote,
                icon: const Icon(Icons.save),
                label: const Text('Save Audio Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    if (_transcription == null) return;

    final title = _titleController.text.isNotEmpty 
        ? _titleController.text 
        : 'Audio Note ${DateTime.now().toString().split('.')[0]}';

    // Build content
    final content = StringBuffer();
    content.writeln('🎤 Audio Transcription\n');
    content.writeln(_transcription);
    
    if (_translation != null) {
      content.writeln('\n\n🌍 Translation\n');
      content.writeln(_translation);
    }

    // Parse tags
    final tagsText = _tagsController.text.trim();
    final tags = tagsText.isNotEmpty
        ? tagsText.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : <String>['audio', 'voice-note'];

    // Create note
    final note = NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags,
      mode: _mode,
      attachments: [],
      isFavorite: false,
      priority: 0,
    );

    try {
      await ref.read(notesProvider.notifier).addNote(note);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Audio note saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to previous screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
