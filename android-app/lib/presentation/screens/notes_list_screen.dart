// lib/presentation/screens/notes_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/note_model.dart';
import '../providers/app_providers.dart';
import '../widgets/sync_status_widget.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, work, personal
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesProvider.notifier).loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      ref.read(notesProvider.notifier).loadNotes();
    } else {
      ref.read(notesProvider.notifier).searchNotes(query);
    }
  }

  List<NoteModel> _filterNotes(List<NoteModel> notes) {
    switch (_selectedFilter) {
      case 'work':
        return notes.where((note) => note.mode == 'work').toList();
      case 'personal':
        return notes.where((note) => note.mode == 'personal').toList();
      default:
        return notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                ),
                onChanged: _performSearch,
              )
            : const Text('All Notes'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                ref.read(notesProvider.notifier).loadNotes();
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedFilter == 'all',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'all');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Work'),
                  selected: _selectedFilter == 'work',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'work');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Personal'),
                  selected: _selectedFilter == 'personal',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'personal');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Notes list
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                final filteredNotes = _filterNotes(notes);
                
                if (filteredNotes.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No notes found'),
                        Text('Try adjusting your search or filter'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredNotes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return _NoteListCard(note: note);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading notes: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(notesProvider.notifier).loadNotes(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/editor'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NoteListCard extends ConsumerWidget {
  final NoteModel note;
  
  const _NoteListCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeColor = note.mode == 'work' 
        ? AppColors.workBlue 
        : AppColors.personalGreen;

    return Card(
      child: InkWell(
        onTap: () => context.push('/editor?id=${note.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: modeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: modeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      note.mode.toUpperCase(),
                      style: TextStyle(
                        color: modeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        _showDeleteDialog(context, ref);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note.title.isEmpty ? 'Untitled Note' : note.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                note.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(note.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  if (note.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: note.tags.take(3).map((tag) => 
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
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(notesProvider.notifier).deleteNote(note.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final currentMode = ref.watch(appModeProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${currentMode.capitalize()} Notes'),
        actions: [
          // Manual sync button
          IconButton(
            onPressed: syncStatus.isSyncing ? null : () {
              ref.read(syncStatusProvider.notifier).syncNotes();
            },
            icon: syncStatus.isSyncing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Sync status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${notes.length} notes',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SyncStatusWidget(),
              ],
            ),
          ),
          
          // Notes list
          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_add,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notes yet',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to create your first note',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(note.title),
                          subtitle: Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Show sync status for individual notes if needed
                              if (note.needsSync ?? false)
                                Icon(
                                  Icons.sync,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/editor',
                              arguments: note.id,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/editor');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
