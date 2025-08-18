//INCOMPLETE
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
                  _sortAscending = !
