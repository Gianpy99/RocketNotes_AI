// lib/ui/widgets/note_editor/tag_input.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'smart_tag_suggestions.dart';

class TagInput extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;
  final String? noteContent;
  final List<String>? recentTags;

  const TagInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.noteContent,
    this.recentTags,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim().toLowerCase();
    if (trimmedTag.isNotEmpty && !widget.tags.contains(trimmedTag)) {
      final newTags = [...widget.tags, trimmedTag];
      widget.onTagsChanged(newTags);
      _controller.clear();
    }
  }

  void _removeTag(String tag) {
    final newTags = widget.tags.where((t) => t != tag).toList();
    widget.onTagsChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Smart Suggestions
        if (widget.noteContent != null && widget.noteContent!.isNotEmpty)
          SmartTagSuggestions(
            content: widget.noteContent!,
            currentTags: widget.tags,
            recentTags: widget.recentTags ?? [],
            onTagsSelected: widget.onTagsChanged,
          ),
        
        // Current Tags
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeTag(tag),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                deleteIconColor: AppColors.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // Tag Input Field
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Add tags...',
            prefixIcon: const Icon(Icons.local_offer_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _addTag(_controller.text),
            ),
          ),
          onSubmitted: _addTag,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
