// lib/presentation/widgets/recent_notes.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/note_model.dart';
import '../providers/app_providers.dart';

class RecentNotes extends ConsumerStatefulWidget {
  final String mode;
  
  const RecentNotes({super.key, required this.mode});

  @override
  ConsumerState<RecentNotes> createState() => _RecentNotesState();
}

class _RecentNotesState extends ConsumerState<RecentNotes> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesProvider.notifier).loadNotesByMode(widget.mode);
    });
  }

  @override
  void didUpdateWidget(RecentNotes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      ref.read(notesProvider.notifier).loadNotesByMode(widget.mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Notes (${widget.mode.toUpperCase()})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/notes'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.note, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No notes yet'),
                          Text('Tap + to create your first note'),
                        ],
                      ),
                    );
                  }
                  
                  final recentNotes = notes.take(5).toList();
                  return ListView.separated(
                    itemCount: recentNotes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final note = recentNotes[index];
                      return _NoteCard(note: note);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text('Error loading notes: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final modeColor = note.mode == 'work' 
        ? AppColors.workBlue 
        : AppColors.personalGreen;
    
    return GestureDetector(
      onTap: () => context.push('/editor?id=${note.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.left(color: modeColor, width: 4),
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title.isEmpty ? 'Untitled Note' : note.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              note.content,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(note.updatedAt),
                  style: Theme.of(context).textTheme.caption?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                if (note.tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: note.tags.take(2).map((tag) => 
                      Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 10)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )
                    ).toList(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

