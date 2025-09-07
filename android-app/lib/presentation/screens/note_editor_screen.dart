// lib/presentation/screens/note_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/openai_service.dart';
import '../../core/themes/app_colors.dart';
import '../../data/models/note_model.dart';
import '../providers/app_providers.dart';
import '../../ui/widgets/note_editor/tag_input.dart';

/// Enum per i tipi di funzionalità AI disponibili
enum AIFeatureType {
  improve,
  summarize,
  correctGrammar,
  generateSuggestions,
  generateTitle,
  generateTags,
}

extension AIFeatureTypeExtension on AIFeatureType {
  String get displayName {
    switch (this) {
      case AIFeatureType.improve:
        return 'Migliora Testo';
      case AIFeatureType.summarize:
        return 'Riassumi';
      case AIFeatureType.correctGrammar:
        return 'Correggi Grammatica';
      case AIFeatureType.generateSuggestions:
        return 'Suggerimenti';
      case AIFeatureType.generateTitle:
        return 'Genera Titolo';
      case AIFeatureType.generateTags:
        return 'Genera Tag';
    }
  }

  String get description {
    switch (this) {
      case AIFeatureType.improve:
        return 'Migliora la chiarezza e la struttura del testo';
      case AIFeatureType.summarize:
        return 'Crea un riassunto conciso del contenuto';
      case AIFeatureType.correctGrammar:
        return 'Correggi errori grammaticali e ortografici';
      case AIFeatureType.generateSuggestions:
        return 'Suggerisci modi per espandere il contenuto';
      case AIFeatureType.generateTitle:
        return 'Genera un titolo appropriato';
      case AIFeatureType.generateTags:
        return 'Crea tag automatici basati sul contenuto';
    }
  }

  IconData get icon {
    switch (this) {
      case AIFeatureType.improve:
        return Icons.auto_fix_high;
      case AIFeatureType.summarize:
        return Icons.summarize;
      case AIFeatureType.correctGrammar:
        return Icons.spellcheck;
      case AIFeatureType.generateSuggestions:
        return Icons.lightbulb;
      case AIFeatureType.generateTitle:
        return Icons.title;
      case AIFeatureType.generateTags:
        return Icons.tag;
    }
  }
}

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final String? voiceNotePath;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.voiceNotePath,
  });

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
  String? _voiceNotePath;
  String _selectedMode = 'personal'; // Default to personal mode

  @override
  void initState() {
    super.initState();
    _voiceNotePath = widget.voiceNotePath;
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
          _selectedMode = note.mode; // Set the mode from the existing note
          _isLoading = false;
        });
        return;
      }
    } else if (_voiceNotePath != null) {
      // Handle voice note - create a new note with voice note content
      setState(() {
        _titleController.text = 'Voice Note - ${DateTime.now().toString().split(' ')[0]}';
        _contentController.text = '[Voice recording attached]\n\n🎵 Voice Note: $_voiceNotePath\n\nTranscribe or add notes here...';
        _tags = ['voice-note'];
        _isLoading = false;
        _hasUnsavedChanges = true;
      });
      return;
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      return;
    }

    final now = DateTime.now();
    
    debugPrint('[SAVE NOTE]  Creating/updating note with selected mode: $_selectedMode');

    final note = _currentNote?.copyWith(
      title: _titleController.text.trim().isEmpty 
          ? 'Untitled Note' 
          : _titleController.text.trim(),
      content: _contentController.text,
      mode: _selectedMode, // Use the selected mode instead of global app mode
      updatedAt: now,
      tags: _tags,
    ) ?? NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim().isEmpty 
          ? 'Untitled Note' 
          : _titleController.text.trim(),
      content: _contentController.text,
      mode: _selectedMode, // Use the selected mode instead of global app mode
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
      
      // Debug: Log the saved note
      debugPrint('📝 Note saved: ${note.id} - ${note.title}');
      
      // Show dialog asking what to do next
      await _showPostSaveDialog();
    }
  }

  Future<void> _shareNote() async {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Note'
        : _titleController.text.trim();
    final content = _contentController.text.trim();
    final tags = _tags.isNotEmpty ? '\n\nTags: ${_tags.join(', ')}' : '';

    final shareText = '$title\n\n$content$tags';

    try {
      // ignore: deprecated_member_use
      await Share.share(shareText, subject: title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share note: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            onPressed: () => Navigator.of(context).pop(true),
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
                  case 'share':
                    _shareNote();
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
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share'),
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
            // Mode Selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Text(
                    'Note Mode:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Personal Mode Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMode = 'personal';
                          _hasUnsavedChanges = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _selectedMode == 'personal' 
                              ? AppColors.personalGreen.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedMode == 'personal' 
                                ? AppColors.personalGreen
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: _selectedMode == 'personal' 
                                  ? AppColors.personalGreen
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Personal',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _selectedMode == 'personal' 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                color: _selectedMode == 'personal' 
                                    ? AppColors.personalGreen
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Work Mode Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMode = 'work';
                          _hasUnsavedChanges = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _selectedMode == 'work' 
                              ? AppColors.workBlue.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedMode == 'work' 
                                ? AppColors.workBlue
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work,
                              size: 14,
                              color: _selectedMode == 'work' 
                                  ? AppColors.workBlue
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Work',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _selectedMode == 'work' 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                color: _selectedMode == 'work' 
                                    ? AppColors.workBlue
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_hasUnsavedChanges)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
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
                    TagInput(
                      tags: _tags,
                      onTagsChanged: (newTags) {
                        setState(() {
                          _tags = newTags;
                          _hasUnsavedChanges = true;
                        });
                      },
                      noteContent: _contentController.text,
                      recentTags: ref.watch(appSettingsProvider).maybeWhen(
                        data: (settings) => settings.pinnedTags,
                        orElse: () => [],
                      ),
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
                            onPressed: _showAIFeaturesMenu,
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

  void _showAIFeaturesMenu() {
    if (OpenAIService.isApiKeyMissing()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('API Key Required'),
          content: const Text(
            'To use AI features, you need to configure your OpenAI API key in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to settings - you might need to implement this navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please go to Settings > AI to configure your API key'),
                  ),
                );
              },
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      );
      return;
    }

    final currentText = _contentController.text.trim();
    if (currentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                'AI Enhancement Tools',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Choose an AI feature to enhance your note:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: AIFeatureType.values.map((feature) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(feature.icon, color: AppColors.primary),
                      title: Text(feature.displayName),
                      subtitle: Text(feature.description),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _executeAIFeature(feature),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _executeAIFeature(AIFeatureType feature) async {
    Navigator.of(context).pop(); // Close the menu

    final currentText = _contentController.text.trim();
    if (currentText.isEmpty) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processing with AI...'),
          ],
        ),
      ),
    );

    try {
      String result = '';
      String resultTitle = '';

      switch (feature) {
        case AIFeatureType.improve:
          final openAIService = OpenAIService();
          final prompt = '''
Migliora il seguente testo rendendolo più chiaro, professionale e ben strutturato.
Mantieni il significato originale ma migliora la grammatica, la struttura e la leggibilità.
Se il testo è in italiano, rispondi in italiano. Se è in inglese, rispondi in inglese.

Testo originale:
$currentText

Testo migliorato:
''';
          result = await openAIService.generateText(prompt);
          resultTitle = 'Improved Text';
          break;
        case AIFeatureType.summarize:
          final openAIService = OpenAIService();
          final prompt = '''
Crea un riassunto conciso ma completo del seguente testo.
Il riassunto dovrebbe catturare i punti principali e le idee chiave.
Mantieni un tono professionale e usa un linguaggio chiaro.

Testo da riassumere:
$currentText

Riassunto:
''';
          result = await openAIService.generateText(prompt);
          resultTitle = 'Summary';
          break;
        case AIFeatureType.correctGrammar:
          final openAIService = OpenAIService();
          final prompt = '''
Correggi la grammatica, l'ortografia e la punteggiatura del seguente testo.
Mantieni il significato originale e lo stile di scrittura.
Se il testo è in italiano, correggi secondo le regole grammaticali italiane.
Se è in inglese, correggi secondo le regole grammaticali inglesi.

Testo originale:
$currentText

Testo corretto:
''';
          result = await openAIService.generateText(prompt);
          resultTitle = 'Corrected Text';
          break;
        case AIFeatureType.generateSuggestions:
          final openAIService = OpenAIService();
          final prompt = '''
Analizza il seguente testo e fornisci suggerimenti concreti per espanderlo e migliorarlo.
Suggerisci:
1. Argomenti aggiuntivi da coprire
2. Esempi o casi d'uso da aggiungere
3. Domande che il testo dovrebbe rispondere
4. Strutture o sezioni che potrebbero essere aggiunte

Testo da analizzare:
$currentText

Suggerimenti:
''';
          result = await openAIService.generateText(prompt);
          resultTitle = 'Suggestions';
          break;
        case AIFeatureType.generateTitle:
          final openAIService = OpenAIService();
          final prompt = '''
Genera un titolo accattivante e descrittivo per il seguente testo.
Il titolo dovrebbe essere conciso (max 10 parole) ma informativo.
Se il testo è in italiano, genera un titolo in italiano.
Se è in inglese, genera un titolo in inglese.

Testo:
$currentText

Titolo:
''';
          result = (await openAIService.generateText(prompt)).trim();
          resultTitle = 'Generated Title';
          _titleController.text = result;
          setState(() {
            _hasUnsavedChanges = true;
          });
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Title generated and applied!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return;
        case AIFeatureType.generateTags:
          final openAIService = OpenAIService();
          final prompt = '''
Analizza il seguente testo e genera 3-5 tag rilevanti che descrivano il contenuto principale.
I tag dovrebbero essere parole chiave concise, separate da virgola.
Se il testo è in italiano, usa tag in italiano.
Se è in inglese, usa tag in inglese.

Testo:
$currentText

Tag (separati da virgola):
''';
          final tagsString = await openAIService.generateText(prompt);
          final tags = tagsString
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();
          resultTitle = 'Generated Tags';
          result = tags.join(', ');
          // Add tags to existing tags
          final existingTags = Set<String>.from(_tags);
          existingTags.addAll(tags);
          setState(() {
            _tags = existingTags.toList();
            _hasUnsavedChanges = true;
          });
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Tags generated and added!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return;
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show result dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(resultTitle),
            content: SingleChildScrollView(
              child: Text(result),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (feature == AIFeatureType.improve ||
                      feature == AIFeatureType.correctGrammar) {
                    _contentController.text = result;
                  } else {
                    // For summary and suggestions, append to existing content
                    final currentContent = _contentController.text;
                    _contentController.text = '$currentContent\n\n--- $resultTitle ---\n$result';
                  }
                  setState(() {
                    _hasUnsavedChanges = true;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ AI enhancement applied!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI processing failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPostSaveDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note Saved!'),
        content: const Text('What would you like to do next?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('new'),
            child: const Text('Create New Note'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('home'),
            child: const Text('Go to Home'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('stay'),
            child: const Text('Stay Here'),
          ),
        ],
      ),
    );

    if (result == 'new') {
      // Clear the current note and start fresh
      setState(() {
        _currentNote = null;
        _titleController.clear();
        _contentController.clear();
        _tags.clear();
        _hasUnsavedChanges = false;
      });
    } else if (result == 'home') {
      // Navigate back to home screen and refresh notes
      if (mounted) {
        // Invalidate the notes provider to force refresh
        ref.invalidate(notesProvider);
        context.go('/');
      }
    }
    // If 'stay' or null, just stay in the editor
  }
}
