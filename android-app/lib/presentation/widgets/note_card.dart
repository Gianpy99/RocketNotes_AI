import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/note_model.dart';
import '../../core/themes/app_colors.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  
  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWorkMode = note.mode == 'work';
    final modeColor = isWorkMode ? AppColors.workBlue : AppColors.personalGreen;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          context.push('/editor/${note.id}');
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with mode indicator and date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: modeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: modeColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isWorkMode ? Icons.work : Icons.home,
                          size: 14,
                          color: modeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          note.mode.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: modeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(note.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Title
              if (note.title.isNotEmpty) ...[
                Text(
                  note.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              
              // Content preview
              if (note.content.isNotEmpty) ...[
                Text(
                  _extractTextFromContent(note.content),
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Tags and actions row
              Row(
                children: [
                  // Tags
                  if (note.tags.isNotEmpty) ...[
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: note.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ] else 
                    const Spacer(),
                  
                  // Action icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (note.isFavorite)
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.red[400],
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
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

  String _extractTextFromContent(String content) {
    // Simple text extraction from potential rich content
    // This is a basic implementation - you might want to enhance it
    // to properly parse Quill Delta or other rich text formats
    return content.replaceAll(RegExp(r'[{}\[\]":]'), ' ')
                 .replaceAll(RegExp(r'\s+'), ' ')
                 .trim();
  }
}
