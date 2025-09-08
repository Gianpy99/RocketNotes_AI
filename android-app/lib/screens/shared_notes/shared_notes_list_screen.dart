import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shared_note.dart';
import '../../models/note_permission.dart';
import '../../core/services/firebase_service.dart';
import './shared_note_card.dart';

// T039: Sorting options for shared notes
enum SortOption { dateNewest, dateOldest, alphabetical, sharedBy }

// T031: Enhanced shared notes list with pagination and offline support
class SharedNotesListScreen extends ConsumerStatefulWidget {
  const SharedNotesListScreen({super.key});

  @override
  ConsumerState<SharedNotesListScreen> createState() => _SharedNotesListScreenState();
}

class _SharedNotesListScreenState extends ConsumerState<SharedNotesListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isLoadingMore = false; // T032: Loading state for pagination
  bool _hasMoreData = true; // T032: Track if more data is available
  String? _errorMessage; // T036: Error handling
  List<SharedNote> _allSharedNotes = [];
  final FirebaseService _firebaseService = FirebaseService();

  // T032: Pagination variables
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  // T035: Offline support
  bool _isOffline = false;
  List<SharedNote> _cachedNotes = [];

  // T038: Search and filter functionality
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // T039: Sorting functionality
  SortOption _currentSort = SortOption.dateNewest;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll); // T034: Infinite scroll listener
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // T034: Infinite scroll handler
  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        _hasMoreData &&
        !_isOffline) {
      _loadMoreData();
    }
  }

  // T031: Enhanced data loading with service integration
  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    setState(() {
      _errorMessage = null;
      _lastDocument = null;
      _hasMoreData = true;
    });

    try {
      // T035: Check connectivity and load from cache if offline
      final isOnline = await _checkConnectivity();
      setState(() => _isOffline = !isOnline);

      if (_isOffline && _cachedNotes.isNotEmpty) {
        // Load from cache
        _processNotesData(_cachedNotes);
        return;
      }

      // T031: Load shared notes from service
      final notes = await _fetchSharedNotesFromService(limit: _pageSize);

      // T035: Cache the notes for offline use
      _cachedNotes = List.from(notes);

      _processNotesData(notes);

    } catch (e) {
      debugPrint('Error loading shared notes: $e');
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });

      // T035: Try to load from cache if service fails
      if (_cachedNotes.isNotEmpty) {
        _processNotesData(_cachedNotes);
      }
    }
  }

  // T032: Load more data for pagination
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData || _isOffline) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreNotes = await _fetchSharedNotesFromService(
        limit: _pageSize,
        startAfter: _lastDocument,
      );

      if (moreNotes.isEmpty) {
        setState(() => _hasMoreData = false);
      } else {
        setState(() {
          _allSharedNotes.addAll(moreNotes);
          _lastDocument = moreNotes.last as DocumentSnapshot?; // Update for pagination
        });
      }
    } catch (e) {
      debugPrint('Error loading more shared notes: $e');
      setState(() => _errorMessage = _getErrorMessage(e));
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  // T031: Mock service call (replace with actual service when ready)
  Future<List<SharedNote>> _fetchSharedNotesFromService({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate potential errors (remove in production)
    if (DateTime.now().second % 10 == 0) { // 10% chance of error
      throw Exception('Network error occurred while loading shared notes');
    }

    // Mock data - replace with actual service call
    final currentUserId = _getCurrentUserId();
    final mockNotes = <SharedNote>[];

    // Generate mock shared notes
    for (int i = 0; i < limit; i++) {
      final noteId = 'note_${i + 1}';
      final sharedBy = i % 3 == 0 ? currentUserId! : 'user_${i % 5 + 1}';

      mockNotes.add(SharedNote(
        id: 'shared_${i + 1}',
        noteId: noteId,
        familyId: 'family_1',
        sharedBy: sharedBy,
        sharedAt: DateTime.now().subtract(Duration(days: i)),
        title: 'Shared Note ${i + 1}',
        description: i % 3 == 0 ? 'This is a sample shared note with description' : null,
        permission: NotePermission(
          id: 'perm_${i + 1}',
          sharedNoteId: 'shared_${i + 1}',
          userId: currentUserId!,
          familyMemberId: 'member_$currentUserId',
          canView: true,
          canEdit: i % 4 == 0,
          canComment: i % 2 == 0,
          canDelete: false,
          canShare: i % 3 == 0,
          canExport: i % 5 == 0,
          canInviteCollaborators: false,
          receiveNotifications: true,
          grantedAt: DateTime.now(),
          grantedBy: sharedBy,
          isActive: true,
        ),
        requiresApproval: i % 7 == 0,
        status: i % 7 == 0 ? SharingStatus.pending : SharingStatus.approved,
        approvedBy: i % 7 != 0 ? sharedBy : null,
        approvedAt: i % 7 != 0 ? DateTime.now() : null,
        expiresAt: i % 10 == 0 ? DateTime.now().add(const Duration(days: 30)) : null,
        allowCollaboration: i % 3 == 0,
        updatedAt: DateTime.now().subtract(Duration(hours: i)),
      ));
    }

    return mockNotes;
  }

  // T035: Check connectivity status
  Future<bool> _checkConnectivity() async {
    // Simple connectivity check - replace with actual connectivity plugin
    try {
      // Simulate connectivity check
      await Future.delayed(const Duration(milliseconds: 100));
      return true; // Assume online for now
    } catch (e) {
      return false;
    }
  }

  // T031: Process notes data and update UI
  void _processNotesData(List<SharedNote> notes) {
    setState(() {
      _allSharedNotes = notes;
      _isLoading = false;
    });
  }

  // T036: Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.toString().contains('permission')) {
      return 'You do not have permission to view shared notes.';
    } else {
      return 'Failed to load shared notes. Please try again.';
    }
  }

  String? _getCurrentUserId() {
    return _firebaseService.currentUser?.uid;
  }

  // T038: Filter notes based on search query
  List<SharedNote> _filterNotes(List<SharedNote> notes) {
    if (_searchQuery.isEmpty) return notes;

    return notes.where((note) {
      final titleMatch = note.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final descriptionMatch = note.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      return titleMatch || descriptionMatch;
    }).toList();
  }

  // T039: Sort notes based on current sort option
  List<SharedNote> _sortNotes(List<SharedNote> notes) {
    final sortedNotes = List<SharedNote>.from(notes);

    switch (_currentSort) {
      case SortOption.dateNewest:
        sortedNotes.sort((a, b) => b.sharedAt.compareTo(a.sharedAt));
        break;
      case SortOption.dateOldest:
        sortedNotes.sort((a, b) => a.sharedAt.compareTo(b.sharedAt));
        break;
      case SortOption.alphabetical:
        sortedNotes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.sharedBy:
        sortedNotes.sort((a, b) => a.sharedBy.compareTo(b.sharedBy));
        break;
    }

    return sortedNotes;
  }

  // T038: Handle search query changes
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  // T039: Handle sort option changes
  void _onSortChanged(SortOption? sortOption) {
    if (sortOption != null) {
      setState(() {
        _currentSort = sortOption;
      });
    }
  }

  // T038: Show search dialog
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Shared Notes'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by title or description...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _onSearchChanged,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Notes'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'My Shares'),
            Tab(text: 'Received'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          // T039: Sort dropdown
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort notes',
            onSelected: _onSortChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.dateNewest,
                child: Text('Newest First'),
              ),
              const PopupMenuItem(
                value: SortOption.dateOldest,
                child: Text('Oldest First'),
              ),
              const PopupMenuItem(
                value: SortOption.alphabetical,
                child: Text('Alphabetical'),
              ),
              const PopupMenuItem(
                value: SortOption.sharedBy,
                child: Text('By Sharer'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Search notes',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => context.push('/share-note'),
            tooltip: 'Share Note',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotesList(_allSharedNotes),
                    _buildNotesList(_allSharedNotes.where((note) => note.sharedBy == _getCurrentUserId()).toList()),
                    _buildNotesList(_allSharedNotes.where((note) => note.sharedBy != _getCurrentUserId()).toList()),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/share-note'),
        backgroundColor: AppColors.primaryBlue,
        tooltip: 'Share New Note',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNotesList(List<SharedNote> notes) {
    if (notes.isEmpty) {
      return _buildEmptyState();
    }

    // T038 & T039: Apply filtering and sorting
    final filteredNotes = _filterNotes(notes);
    final sortedNotes = _sortNotes(filteredNotes);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: sortedNotes.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == sortedNotes.length) {
            // T032: Loading indicator for pagination
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final note = sortedNotes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SharedNoteCard(
              sharedNote: note,
              onTap: () => context.push('/shared-note/${note.id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.share_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No shared notes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your first note with your family!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/share-note'),
            icon: const Icon(Icons.share),
            label: const Text('Share a Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // T036: Build error state widget
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Shared Notes',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
