// ==========================================
// lib/data/services/search_service.dart
// ==========================================
import '../models/note_model.dart';
import '../repositories/note_repository.dart';
import '../../core/constants/app_constants.dart';

class SearchService {
  final NoteRepository _noteRepository;

  SearchService({required NoteRepository noteRepository})
      : _noteRepository = noteRepository;

  // Perform advanced search
  Future<SearchResult> searchNotes({
    required String query,
    String? mode,
    List<String>? tags,
    bool? isFavorite,
    int? priority,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool includeArchived = false,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return SearchResult.empty();
      }

      List<NoteModel> notes = includeArchived
          ? (await _noteRepository.exportAllNotes())
              .map((json) => NoteModel.fromJson(json))
              .toList()
          : await _noteRepository.getAllNotes();

      // Apply filters
      notes = _applyFilters(notes, mode, tags, isFavorite, priority, dateFrom, dateTo);

      // Perform text search with ranking
      final searchResults = _performTextSearch(notes, query);

      return SearchResult(
        query: query,
        results: searchResults,
        totalResults: searchResults.length,
        searchTime: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // Apply various filters
  List<NoteModel> _applyFilters(
    List<NoteModel> notes,
    String? mode,
    List<String>? tags,
    bool? isFavorite,
    int? priority,
    DateTime? dateFrom,
    DateTime? dateTo,
  ) {
    var filteredNotes = notes;

    if (mode != null) {
      filteredNotes = filteredNotes.where((note) => note.mode == mode).toList();
    }

    if (tags != null && tags.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) {
        return tags.any((tag) => note.tags.contains(tag));
      }).toList();
    }

    if (isFavorite != null) {
      filteredNotes = filteredNotes.where((note) => note.isFavorite == isFavorite).toList();
    }

    if (priority != null) {
      filteredNotes = filteredNotes.where((note) => note.priority == priority).toList();
    }

    if (dateFrom != null) {
      filteredNotes = filteredNotes.where((note) => note.createdAt.isAfter(dateFrom)).toList();
    }

    if (dateTo != null) {
      filteredNotes = filteredNotes.where((note) => note.createdAt.isBefore(dateTo)).toList();
    }

    return filteredNotes;
  }

  // Perform text search with ranking
  List<RankedNote> _performTextSearch(List<NoteModel> notes, String query) {
    final queryWords = query.toLowerCase().split(RegExp(r'\W+'));
    final rankedNotes = <RankedNote>[];

    for (final note in notes) {
      final score = _calculateRelevanceScore(note, queryWords);
      if (score > 0) {
        rankedNotes.add(RankedNote(note: note, relevanceScore: score));
      }
    }

    // Sort by relevance score (descending)
    rankedNotes.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return rankedNotes.take(AppConstants.maxSearchResults).toList();
  }

  // Calculate relevance score for a note
  double _calculateRelevanceScore(NoteModel note, List<String> queryWords) {
    double score = 0.0;
    final noteTitle = note.title.toLowerCase();
    final noteContent = note.content.toLowerCase();
    final noteTags = note.tags.map((tag) => tag.toLowerCase()).toList();

    for (final word in queryWords) {
      if (word.isEmpty) continue;

      // Title matches (highest weight)
      if (noteTitle.contains(word)) {
        score += noteTitle == word ? 10.0 : 5.0;
      }

      // Tag matches (high weight)
      for (final tag in noteTags) {
        if (tag.contains(word)) {
          score += tag == word ? 8.0 : 4.0;
        }
      }

      // Content matches (medium weight)
      if (noteContent.contains(word)) {
        score += 2.0;
      }

      // AI summary matches (medium weight)
      if (note.aiSummary != null && note.aiSummary!.toLowerCase().contains(word)) {
        score += 3.0;
      }
    }

    // Boost score for favorites
    if (note.isFavorite) {
      score *= 1.2;
    }

    // Boost score for recent notes
    final daysSinceUpdate = DateTime.now().difference(note.updatedAt).inDays;
    if (daysSinceUpdate < 7) {
      score *= 1.1;
    }

    return score;
  }

  // Get search suggestions based on existing content
  Future<List<String>> getSearchSuggestions(String partialQuery) async {
    try {
      if (partialQuery.trim().isEmpty) return [];

      final allNotes = await _noteRepository.getAllNotes();
      final allTags = await _noteRepository.getAllTags();
      final suggestions = <String>{};

      // Add tag suggestions
      for (final tag in allTags) {
        if (tag.toLowerCase().startsWith(partialQuery.toLowerCase())) {
          suggestions.add(tag);
        }
      }

      // Add title word suggestions
      for (final note in allNotes) {
        final titleWords = note.title.split(RegExp(r'\W+'));
        for (final word in titleWords) {
          if (word.length > 2 && word.toLowerCase().startsWith(partialQuery.toLowerCase())) {
            suggestions.add(word);
          }
        }
      }

      return suggestions.take(10).toList();
    } catch (e) {
      print('Error getting search suggestions: $e');
      return [];
    }
  }
}

// Search result classes
class SearchResult {
  final String query;
  final List<RankedNote> results;
  final int totalResults;
  final DateTime searchTime;

  SearchResult({
    required this.query,
    required this.results,
    required this.totalResults,
    required this.searchTime,
  });

  factory SearchResult.empty() {
    return SearchResult(
      query: '',
      results: [],
      totalResults: 0,
      searchTime: DateTime.now(),
    );
  }
}

class RankedNote {
  final NoteModel note;
  final double relevanceScore;

  RankedNote({
    required this.note,
    required this.relevanceScore,
  });
}
