// lib/data/repositories/note_repository.dart
import 'package:hive/hive.dart';
import '../models/note_model.dart';
import '../../core/debug/debug_logger.dart';
import '../../core/constants/app_constants.dart';

class NoteRepository {
  // Use the typed box for notes
  final Box<NoteModel> notesBox = Hive.box<NoteModel>(AppConstants.notesBox);

  Future<List<NoteModel>> getAllNotes() async {
    DebugLogger().log('🔍 Repository: Getting all notes from box...');
    DebugLogger().log('📦 Box status: isOpen=${notesBox.isOpen}, length=${notesBox.length}');
    
    final notes = notesBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    DebugLogger().log('📋 Repository: Loaded ${notes.length} notes');
    
    // Debug: List all notes
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      DebugLogger().log('📝 Note $i: "${note.title}" (${note.mode}) - ${note.content.substring(0, note.content.length > 50 ? 50 : note.content.length)}...');
    }
    
    return notes;
  }

  Future<List<NoteModel>> getNotesByMode(String mode) async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.mode == mode).toList();
  }

  Future<NoteModel?> getNoteById(String id) async {
    return notesBox.get(id);
  }

  Future<void> saveNote(NoteModel note) async {
    try {
      DebugLogger().log('🔄 Repository: Saving note ${note.id} to Hive box...');
      DebugLogger().log('📦 Box status: isOpen=${notesBox.isOpen}, length=${notesBox.length}');
      
      await notesBox.put(note.id, note);
      
      DebugLogger().log('✅ Repository: Note saved successfully. Box now has ${notesBox.length} notes.');
      
      // Verify the note was saved
      final savedNote = notesBox.get(note.id);
      if (savedNote != null) {
        DebugLogger().log('🔍 Repository: Verification successful - note found in box');
      } else {
        DebugLogger().log('⚠️ Repository: Warning - note not found after save');
      }
    } catch (e, stackTrace) {
      DebugLogger().log('❌ Repository: Error saving note: $e');
      DebugLogger().log('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteNote(String id) async {
    await notesBox.delete(id);
  }

  Future<List<NoteModel>> searchNotes(String query, {String? mode}) async {
    final allNotes = await getAllNotes();
    final lowercaseQuery = query.toLowerCase();
    
    var filteredNotes = allNotes.where((note) {
      return note.title.toLowerCase().contains(lowercaseQuery) ||
             note.content.toLowerCase().contains(lowercaseQuery) ||
             note.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    });

    if (mode != null) {
      filteredNotes = filteredNotes.where((note) => note.mode == mode);
    }

    return filteredNotes.toList();
  }

  Future<void> archiveNote(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final archivedNote = note.copyWith(isArchived: true);
      await saveNote(archivedNote);
    }
  }

  Future<void> toggleFavorite(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
      await saveNote(updatedNote);
    }
  }

  Future<List<NoteModel>> getNotesByTag(String tag) async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.tags.contains(tag)).toList();
  }

  Future<void> deleteMultipleNotes(List<String> ids) async {
    for (final id in ids) {
      await deleteNote(id);
    }
  }

  Future<void> archiveMultipleNotes(List<String> ids) async {
    for (final id in ids) {
      await archiveNote(id);
    }
  }

  Future<List<NoteModel>> getRecentNotes({int days = 7}) async {
    final allNotes = await getAllNotes();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return allNotes
        .where((note) => note.updatedAt.isAfter(cutoffDate))
        .toList();
  }

  Future<List<String>> getAllTags() async {
    final allNotes = await getAllNotes();
    final tagSet = <String>{};
    
    for (final note in allNotes) {
      tagSet.addAll(note.tags);
    }
    
    return tagSet.toList()..sort();
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final allNotes = await getAllNotes();
    final workNotes = allNotes.where((note) => note.mode == 'work').length;
    final personalNotes = allNotes.where((note) => note.mode == 'personal').length;
    final archivedNotes = allNotes.where((note) => note.isArchived).length;
    final favoriteNotes = allNotes.where((note) => note.isFavorite).length;
    
    return {
      'total': allNotes.length,
      'work': workNotes,
      'personal': personalNotes,
      'archived': archivedNotes,
      'favorites': favoriteNotes,
      'tags': (await getAllTags()).length,
    };
  }

  Future<List<NoteModel>> exportAllNotes() async {
    return getAllNotes();
  }

  Future<void> importNotes(List<NoteModel> notes) async {
    for (final note in notes) {
      await saveNote(note);
    }
  }

  Future<void> clearAllNotes() async {
    await notesBox.clear();
  }
}
