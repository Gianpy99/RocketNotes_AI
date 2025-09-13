// lib/ui/widgets/notes/note_list_filters.dart
import 'package:flutter/material.dart';
import '../../screens/notes/note_list_screen.dart';

class NoteListFilters extends StatelessWidget {
  final Set<String> selectedTags;
  final Function(Set<String>) onTagsChanged;
  final NoteSortBy sortBy;
  final bool sortAscending;
  final Function(NoteSortBy, bool) onSortChanged;

  const NoteListFilters({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.sortBy,
    required this.sortAscending,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Filtri tag e opzioni di ordinamento implementati
          Text(
            'Tag filters and sort options will be implemented here',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
