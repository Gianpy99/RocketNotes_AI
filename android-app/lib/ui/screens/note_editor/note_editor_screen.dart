// lib/ui/screens/note_editor/note_editor_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:rocket_notes_ai/core/constants/app_colors.dart';
import 'package:rocket_notes_ai/data/models/note_model.dart';
import 'package:rocket_notes_ai/presentation/providers/app_providers.dart';
import 'package:rocket_notes_ai/ui/widgets/common/gradient_background.dart';
import 'package:rocket_notes_ai/ui/widgets/note_editor/editor_toolbar.dart';
import 'package:rocket_notes_ai/ui/widgets/note_editor/tag_input.dart';
import 'package:rocket_notes_ai/ui/widgets/note_editor/ai_suggestions.dart';
import 'package:rocket_notes_ai/ui/widgets/note_editor/ai_content_suggestions.dart';
import 'package:rocket_notes_ai/ui/widgets/common/confirmation_dialog.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final Map<String, dynamic>? initialData;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.initialData,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen>
    with TickerProviderStateMixin {
  late TextEditingController _titleController;
  late quill.QuillController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  late AnimationController _saveAnimationController;
  Timer? _autoSaveTimer;
  
  List<String> _tags = [];
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  bool _isSaving = false;
  Note? _originalNote;
  String? _nfcTagId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadNote();
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _contentController = quill.QuillController.basic();
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Listen for changes
    _titleController.addListener(_onContentChanged);
    _contentController.document.changes.listen((_) => _onContentChanged());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _saveAnimationController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
    
    // Auto-save with debouncing
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (_hasUnsavedChanges && mounted) {
        _saveNote(showSnackBar: false);
      }
    });
  }

  Future<void> _loadNote() async {
    if (widget.noteId == null) {
      _handleInitialData();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final noteRepository = ref.read(noteRepositoryProvider);
      final note = await noteRepository.getNoteById(widget.noteId!);
      
      if (note != null && mounted) {
        setState(() {
          _originalNote = note;
          _titleController.text = note.title;
          
          // Handle content loading - use plain text content
          if (note.content.isNotEmpty) {
            _contentController.document = quill.Document.fromJson([
              {'insert': '${note.content}\n'}
            ]);
          } else {
            _contentController.document = quill.Document();
          }
          
          _tags = List.from(note.tags);
          _nfcTagId = note.nfcTagId;
          _hasUnsavedChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load note: ${e.toString()}');
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      
      if (data.containsKey('title')) {
        _titleController.text = data['title'];
      }
      
      if (data.containsKey('content')) {
        _contentController.document = quill.Document.fromJson([
          {'insert': data['content'] + '\n'}
        ]);
      }
      
      if (data.containsKey('tags')) {
        _tags = List<String>.from(data['tags']);
      }
      
      if (data.containsKey('nfcData')) {
        _nfcTagId = data['nfcData'];
      }
      
      // Set current mode from app state
      final currentMode = ref.read(appModeProvider);
      if (!_tags.contains(currentMode)) {
        _tags.add(currentMode);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save them before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null), // Keep editing
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () async {
              await _saveNote(showSnackBar: false);
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save & Leave'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _saveNote({bool showSnackBar = true}) async {
    if (_isSaving) return;
    
    final title = _titleController.text.trim();
    final contentPlain = _contentController.document.toPlainText().trim();
    
    if (title.isEmpty && contentPlain.isEmpty) {
      if (showSnackBar) {
        _showErrorSnackBar('Cannot save empty note');
      }
      return;
    }

    setState(() => _isSaving = true);
    _saveAnimationController.forward();

    try {
      final noteRepository = ref.read(noteRepositoryProvider);
      
      final note = Note(
        id: _originalNote?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.isEmpty ? 'Untitled' : title,
        content: contentPlain,
        tags: _tags,
        createdAt: _originalNote?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        nfcTagId: _nfcTagId,
        mode: ref.read(appModeProvider),
      );

      if (_originalNote != null) {
        await noteRepository.saveNote(note);
      } else {
        await noteRepository.saveNote(note);
      }

      // Trigger AI suggestions if enabled
      final settings = ref.read(appSettingsProvider).value;
      if (settings?.aiEnabled ?? false) {
        _generateAISuggestions(note);
      }

      setState(() {
        _originalNote = note;
        _hasUnsavedChanges = false;
      });

      if (showSnackBar) {
        HapticFeedback.lightImpact();
        _showSuccessSnackBar('Note saved successfully');
      }

    } catch (e) {
      if (showSnackBar) {
        _showErrorSnackBar('Failed to save note: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        _saveAnimationController.reverse();
      }
    }
  }

  Future<void> _generateAISuggestions(Note note) async {
    try {
      final aiService = ref.read(aiServiceProvider);
      final suggestions = await aiService.suggestTags(note.content);
      
      if (suggestions.isNotEmpty && mounted) {
        // Show AI suggestions bottom sheet
        _showAISuggestions(suggestions);
      }
    } catch (e) {
      // Silent fail for AI suggestions
      debugPrint('AI suggestions failed: $e');
    }
  }

  void _showAISuggestions(List<String> suggestions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AISuggestions(
        suggestions: suggestions,
        currentTags: _tags,
        onTagsSelected: (selectedTags) {
          setState(() {
            _tags = <String>{..._tags, ...selectedTags}.toList();
            _hasUnsavedChanges = true;
          });
        },
      ),
    );
  }

  Future<void> _deleteNote() async {
    if (_originalNote == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Delete Note',
        content: 'Are you sure you want to delete this note? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDestructive: true,
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      final noteRepository = ref.read(noteRepositoryProvider);
      await noteRepository.deleteNote(_originalNote!.id);
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate deletion
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete note: ${e.toString()}');
    }
  }

  void _shareNote() {
    if (_originalNote == null) return;
    
    // TODO: Implement share functionality
    // Share.share(shareText, subject: _originalNote!.title);
    _showSuccessSnackBar('Share functionality coming soon!');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: GradientBackground(
          colors: isDarkMode 
            ? AppColors.darkGradient 
            : AppColors.lightGradient,
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // App Bar
                  SafeArea(
                    child: _buildAppBar(context, isDarkMode),
                  ),
                  
                  // Editor Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Title Input
                          TextField(
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode 
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Note title...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: (isDarkMode 
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight).withValues(alpha: 0.6),
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          
                          // Divider
                          Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  (isDarkMode 
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight).withValues(alpha: 0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          
                          // Content Editor
                          Expanded(
                            child: Column(
                              children: [
                                // Toolbar
                                EditorToolbar(
                                  controller: _contentController,
                                  isDarkMode: isDarkMode,
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Content
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: (isDarkMode 
                                        ? AppColors.surfaceDark
                                        : AppColors.surfaceLight).withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: (isDarkMode 
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight).withValues(alpha: 0.2),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: quill.QuillEditor.basic(
                                      controller: _contentController,
                                      focusNode: _contentFocusNode,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // AI Content Suggestions
                          AIContentSuggestions(
                            noteContent: _contentController.document.toPlainText(),
                            onSuggestionApplied: () {
                              // Refresh suggestions after applying one
                              setState(() {
                                _hasUnsavedChanges = true;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Tags Input
                          TagInput(
                            tags: _tags,
                            noteContent: _contentController.document.toPlainText(),
                            recentTags: const ['meeting', 'idea', 'todo', 'important', 'work'], // TODO: Get from settings
                            onTagsChanged: (newTags) {
                              setState(() {
                                _tags = newTags;
                                _hasUnsavedChanges = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom padding for keyboard
                  if (keyboardHeight > 0)
                    SizedBox(height: keyboardHeight),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (_hasUnsavedChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          ),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _originalNote != null ? 'Edit Note' : 'New Note',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode 
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  ),
                ),
                if (_hasUnsavedChanges)
                  Text(
                    'Unsaved changes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),
          
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_originalNote != null) ...[
                IconButton(
                  onPressed: _shareNote,
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Share',
                ),
                
                IconButton(
                  onPressed: _deleteNote,
                  icon: const Icon(Icons.delete_rounded),
                  color: AppColors.error,
                  tooltip: 'Delete',
                ),
                
                const SizedBox(width: 8),
              ],
              
              AnimatedBuilder(
                animation: _saveAnimationController,
                builder: (context, child) {
                  return FilledButton.icon(
                    onPressed: _isSaving ? null : () => _saveNote(),
                    icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                    label: Text(_isSaving ? 'Saving...' : 'Save'),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
