// lib/ui/screens/notes/note_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/note_model.dart';
import '../../../providers/app_providers.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/notes/note_card.dart';
import '../../widgets/notes/note_list_filters.dart';
import '../../widgets/common/search_bar.dart';
import '../../widgets/common/sort_selector.dart';

enum NoteViewMode { list, grid }
enum NoteSortBy { 
  dateModified, 
  dateCreated, 
  title, 
  tags 
}

class NoteListScreen extends ConsumerStatefulWidget {
  const NoteListScreen({super.key});

  @override
  ConsumerState<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends ConsumerState<NoteListScreen>
    with TickerProviderStateMixin {
  late AnimationController _filterAnimationController;
  late AnimationController _fabAnimationController;
  
  final ScrollController _scrollController = ScrollController();
  NoteViewMode _viewMode = NoteViewMode.grid;
  NoteSortBy _sortBy = NoteSortBy.dateModified;
  bool _sortAscending = false;
  bool _showFilters = false;
  String _searchQuery = '';
  Set<String> _selectedTags = {};
  
  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _fabAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsyncValue = ref.watch(notesProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        colors: isDarkMode 
          ? AppColors.darkGradient 
          : AppColors.lightGradient,
        child: Column(
          children: [
            // App Bar
            SafeArea(
              child: _buildAppBar(context, isDarkMode),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchBar(
                hintText: 'Search notes...',
                onChanged: (query) {
                  setState(() => _searchQuery = query);
                  ref.read(searchQueryProvider.notifier).state = query;
                },
              ),
            ),
            
            // Filters
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showFilters ? null : 0,
              child: _showFilters 
                ? NoteListFilters(
                    selectedTags: _selectedTags,
                    onTagsChanged: (tags) => setState(() => _selectedTags = tags),
                    sortBy: _sortBy,
                    sortAscending: _sortAscending,
                    onSortChanged: (sortBy, ascending) {
                      setState(() {
                        _sortBy = sortBy;
                        _sortAscending = ascending;
                      });
                    },
                  )
                : const SizedBox.shrink(),
            ),
            
            // Notes List
            Expanded(
              child: notesAsyncValue.when(
                data: (notes) => _buildNotesList(context, notes, isDarkMode),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => _buildErrorState(
                  context, 
                  error.toString(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) => Transform.scale(
          scale: 0.8 + (_fabAnimationController.value * 0.2),
          child: FloatingActionButton(
            onPressed: () => Navigator.of(context).pushNamed('/note-editor'),
            backgroundColor: AppColors.primary,
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
            ),
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
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          
          Expanded(
            child: Text(
              'All Notes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // View Mode Toggle
          IconButton(
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == NoteViewMode.grid 
                  ? NoteViewMode.list 
                  : NoteViewMode.grid;
              });
            },
            icon: Icon(
              _viewMode == NoteViewMode.grid 
                ? Icons.view_list_rounded
                : Icons.view_module_rounded,
            ),
            tooltip: _viewMode == NoteViewMode.grid 
              ? 'List view' 
              : 'Grid view',
          ),
          
          // Filter Toggle
          IconButton(
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
              if (_showFilters) {
                _filterAnimationController.forward();
              } else {
                _filterAnimationController.reverse();
              }
            },
            icon: AnimatedRotation(
              turns: _showFilters ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.filter_list_rounded,
                color: _showFilters ? AppColors.primary : null,
              ),
            ),
            tooltip: 'Filters',
          ),
          
          // Sort Menu
          PopupMenuButton<NoteSortBy>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (sortBy) {
              setState(() {
                if (_sortBy == sortBy) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = sortBy;
                  _sortAscending = false;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: NoteSortBy.dateModified,
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: _sortBy == NoteSortBy.dateModified 
                        ? AppColors.primary 
                        : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Last Modified'),
                    if (_sortBy == NoteSortBy.dateModified)
                      Icon(
                        _sortAscending 
                          ? Icons.arrow_upward_rounded 
                          : Icons.arrow_downward_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NoteSortBy.dateCreated,
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: _sortBy == NoteSortBy.dateCreated 
                        ? AppColors.primary 
                        : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Date Created'),
                    if (_sortBy == NoteSortBy.dateCreated)
                      Icon(
                        _sortAscending 
                          ? Icons.arrow_upward_rounded 
                          : Icons.arrow_downward_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NoteSortBy.title,
                child: Row(
                  children: [
                    Icon(
                      Icons.title_rounded,
                      color: _sortBy == NoteSortBy.title 
                        ? AppColors.primary 
                        : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Title'),
                    if (_sortBy == NoteSortBy.title)
                      Icon(
                        _sortAscending 
                          ? Icons.arrow_upward_rounded 
                          : Icons.arrow_downward_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NoteSortBy.tags,
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer_rounded,
                      color: _sortBy == NoteSortBy.tags 
                        ? AppColors.primary 
                        : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Tags'),
                    if (_sortBy == NoteSortBy.tags)
                      Icon(
                        _sortAscending 
                          ? Icons.arrow_upward_rounded 
                          : Icons.arrow_downward_rounded,
                        size: 16,
                        color: AppColors.primary,
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

  Widget _buildNotesList(BuildContext context, List<Note> notes, bool isDarkMode) {
    if (notes.isEmpty) {
      return _buildEmptyState(context);
    }

    // Filter notes based on search and tags
    List<Note> filteredNotes = _filterNotes(notes);
    
    // Sort notes
    filteredNotes = _sortNotes(filteredNotes);

    if (filteredNotes.isEmpty) {
      return _buildNoResultsState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(notesProvider);
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimationLimiter(
          child: _viewMode == NoteViewMode.grid 
            ? _buildGridView(filteredNotes)
            : _buildListView(filteredNotes),
        ),
      ),
    );
  }

  Widget _buildGridView(List<Note> notes) {
    return GridView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredGrid(
          position: index,
          duration: const Duration(milliseconds: 600),
          columnCount: 2,
          child: SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(
              child: NoteCard(
                note: notes[index],
                viewMode: NoteCardViewMode.grid,
                onTap: () => _navigateToNoteEditor(notes[index].id),
                onLongPress: () => _showNoteOptions(context, notes[index]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Note> notes) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 600),
          child: SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: NoteCard(
                  note: notes[index],
                  viewMode: NoteCardViewMode.list,
                  onTap: () => _navigateToNoteEditor(notes[index].id),
                  onLongPress: () => _showNoteOptions(context, notes[index]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_rounded,
            size: 80,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first note to get started',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/note-editor'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Note'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedTags.clear();
              });
              ref.read(searchQueryProvider.notifier).state = '';
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load notes',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ref.invalidate(notesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  List<Note> _filterNotes(List<Note> notes) {
    List<Note> filtered = notes;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((note) {
        return note.title.toLowerCase().contains(query) ||
               note.content.toLowerCase().contains(query) ||
               note.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Filter by selected tags
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((note) {
        return _selectedTags.every((tag) => note.tags.contains(tag));
      }).toList();
    }

    return filtered;
  }

  List<Note> _sortNotes(List<Note> notes) {
    final sortedNotes = List<Note>.from(notes);
    
    switch (_sortBy) {
      case NoteSortBy.dateModified:
        sortedNotes.sort((a, b) => _sortAscending 
          ? a.updatedAt.compareTo(b.updatedAt)
          : b.updatedAt.compareTo(a.updatedAt));
        break;
      case NoteSortBy.dateCreated:
        sortedNotes.sort((a, b) => _sortAscending 
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt));
        break;
      case NoteSortBy.title:
        sortedNotes.sort((a, b) => _sortAscending 
          ? a.title.compareTo(b.title)
          : b.title.compareTo(a.title));
        break;
      case NoteSortBy.tags:
        sortedNotes.sort((a, b) {
          final aTagsStr = a.tags.join(',');
          final bTagsStr = b.tags.join(',');
          return _sortAscending 
            ? aTagsStr.compareTo(bTagsStr)
            : bTagsStr.compareTo(aTagsStr);
        });
        break;
    }
    
    return sortedNotes;
  }

  void _navigateToNoteEditor(String noteId) {
    Navigator.of(context).pushNamed(
      '/note-editor',
      arguments: noteId,
    );
  }

  void _showNoteOptions(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToNoteEditor(note.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(context).pop();
                _shareNote(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy_rounded),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.of(context).pop();
                _duplicateNote(note);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_rounded,
                color: AppColors.error,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _deleteNote(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareNote(Note note) {
    // TODO: Implement note sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note sharing coming soon!')),
    );
  }

  void _duplicateNote(Note note) {
    Navigator.of(context).pushNamed(
      '/note-editor',
      arguments: {
        'title': '${note.title} (Copy)',
        'content': note.content,
        'tags': note.tags,
      },
    );
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      final noteRepository = ref.read(noteRepositoryProvider);
      await noteRepository.deleteNote(note.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete note: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
