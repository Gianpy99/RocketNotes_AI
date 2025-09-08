import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shared_note.dart';
import './shared_note_card.dart';

class SharedNotesListScreen extends ConsumerStatefulWidget {
  const SharedNotesListScreen({super.key});

  @override
  ConsumerState<SharedNotesListScreen> createState() => _SharedNotesListScreenState();
}

class _SharedNotesListScreenState extends ConsumerState<SharedNotesListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<SharedNote> _sharedNotes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Load shared notes from service
      // For now, show empty state
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _sharedNotes = [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading shared notes: $e');
      setState(() => _isLoading = false);
    }
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
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotesList(_sharedNotes),
                _buildNotesList(_sharedNotes.where((note) => note.sharedBy == 'currentUserId').toList()),
                _buildNotesList(_sharedNotes.where((note) => note.sharedBy != 'currentUserId').toList()),
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
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
}
