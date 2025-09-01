// lib/ui/widgets/note_editor/note_reader.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../core/constants/app_colors.dart';
import '../../../data/models/note.dart';

class NoteReader extends StatefulWidget {
  final Note note;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const NoteReader({
    super.key,
    required this.note,
    this.onEdit,
    this.onShare,
    this.onDelete,
  });

  @override
  State<NoteReader> createState() => _NoteReaderState();
}

class _NoteReaderState extends State<NoteReader>
    with SingleTickerProviderStateMixin {
  late quill.QuillController _controller;
  late AnimationController _fabAnimationController;
  final bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController.forward();
    _initializeController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _initializeController() {
    try {
      final document = quill.Document.fromJson(
        _parseContent(widget.note.content),
      );
      _controller = quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      // Fallback to plain text if JSON parsing fails
      final document = quill.Document()
        ..insert(0, widget.note.content);
      _controller = quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  List<dynamic> _parseContent(String content) {
    try {
      // Try to parse as Delta JSON
      if (content.startsWith('[') && content.endsWith(']')) {
        return List<dynamic>.from(
          (content as dynamic), // This should be parsed JSON
        );
      }
    } catch (e) {
      // If parsing fails, fall back to plain text
    }
    
    // Return as plain text delta
    return [
      {'insert': content}
    ];
  }

  void _copyToClipboard() {
    final plainText = _controller.document.toPlainText();
    Clipboard.setData(ClipboardData(text: plainText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showMoreActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _MoreActionsSheet(
        note: widget.note,
        onEdit: widget.onEdit,
        onShare: widget.onShare,
        onDelete: widget.onDelete,
        onCopy: _copyToClipboard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: isDarkMode 
              ? AppColors.surfaceDark 
              : AppColors.surfaceLight,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.note.title.isEmpty ? 'Untitled' : widget.note.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
            ),
            actions: [
              IconButton(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Copy',
              ),
              IconButton(
                onPressed: _showMoreActions,
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'More actions',
              ),
            ],
          ),
          
          // Note Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata
                  if (widget.note.createdAt != null ||
                      widget.note.updatedAt != null ||
                      widget.note.tags.isNotEmpty) ...[
                    _MetadataSection(note: widget.note),
                    const SizedBox(height: 24),
                  ],
                  
                  // Content
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                        ? AppColors.surfaceDark.withOpacity(0.5)
                        : AppColors.surfaceLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode 
                          ? AppColors.textSecondaryDark.withOpacity(0.2)
                          : AppColors.textSecondaryLight.withOpacity(0.2),
                      ),
                    ),
                    child: quill.QuillEditor(
                      controller: _controller,
                      scrollController: ScrollController(),
                      scrollable: false,
                      focusNode: FocusNode(),
                      autoFocus: false,
                      readOnly: true,
                      expands: false,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Floating Action Button
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimationController.value,
            child: FloatingActionButton.extended(
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          );
        },
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  final Note note;

  const _MetadataSection({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? AppColors.surfaceDark.withOpacity(0.3)
          : AppColors.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags
          if (note.tags.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 16,
                  color: isDarkMode 
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: note.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // Dates
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: isDarkMode 
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created: ${_formatDate(note.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode 
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      ),
                    ),
                    if (note.updatedAt != note.createdAt)
                      Text(
                        'Updated: ${_formatDate(note.updatedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode 
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _MoreActionsSheet extends StatelessWidget {
  final Note note;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;

  const _MoreActionsSheet({
    required this.note,
    this.onEdit,
    this.onShare,
    this.onDelete,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Actions
          _ActionTile(
            icon: Icons.edit_rounded,
            title: 'Edit Note',
            onTap: () {
              Navigator.pop(context);
              onEdit?.call();
            },
          ),
          
          _ActionTile(
            icon: Icons.copy_rounded,
            title: 'Copy to Clipboard',
            onTap: () {
              Navigator.pop(context);
              onCopy?.call();
            },
          ),
          
          _ActionTile(
            icon: Icons.share_rounded,
            title: 'Share Note',
            onTap: () {
              Navigator.pop(context);
              onShare?.call();
            },
          ),
          
          const Divider(),
          
          _ActionTile(
            icon: Icons.delete_rounded,
            title: 'Delete Note',
            color: Colors.red,
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
