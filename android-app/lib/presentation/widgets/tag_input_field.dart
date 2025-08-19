// ==========================================
// lib/presentation/widgets/tag_input_field.dart
// ==========================================
import 'package:flutter/material.dart';

class TagInputField extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;

  const TagInputField({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final TextEditingController _controller = TextEditingController();

  void _addTag(String tag) {
    if (tag.trim().isEmpty) return;
    if (!widget.tags.contains(tag.trim())) {
      setState(() {
        widget.tags.add(tag.trim());
      });
      widget.onTagsChanged(widget.tags);
    }
    _controller.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      widget.tags.remove(tag);
    });
    widget.onTagsChanged(widget.tags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          children: widget.tags
              .map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  ))
              .toList(),
        ),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Add a tag',
            suffixIcon: Icon(Icons.add),
          ),
          onSubmitted: _addTag,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
