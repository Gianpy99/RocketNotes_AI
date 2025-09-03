// lib/ui/widgets/note_editor/ai_suggestions.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AISuggestions extends StatefulWidget {
  final List<String> suggestions;
  final List<String> currentTags;
  final Function(List<String>) onTagsSelected;

  const AISuggestions({
    super.key,
    required this.suggestions,
    required this.currentTags,
    required this.onTagsSelected,
  });

  @override
  State<AISuggestions> createState() => _AISuggestionsState();
}

class _AISuggestionsState extends State<AISuggestions> {
  final Set<String> _selectedTags = {};

  @override
  Widget build(BuildContext context) {
    final availableSuggestions = widget.suggestions
        .where((tag) => !widget.currentTags.contains(tag))
        .toList();

    if (availableSuggestions.isEmpty) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Tag Suggestions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSuggestions.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _selectedTags.isEmpty
                    ? null
                    : () {
                        widget.onTagsSelected(_selectedTags.toList());
                        Navigator.of(context).pop();
                      },
                child: Text('Add ${_selectedTags.length} tags'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
