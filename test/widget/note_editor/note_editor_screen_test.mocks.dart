// Mock file for NoteRepository
// ignore_for_file: non_constant_identifier_names, prefer_const_constructors_in_immutables

import '../../../android-app/lib/data/repositories/note_repository.dart' as _i2;
import '../../../android-app/lib/data/models/note_model.dart' as _i3;

class MockNoteRepository implements _i2.NoteRepository {
  // Mock the notesBox getter
  @override
  dynamic get notesBox => null;
  @override
  Future<List<_i3.NoteModel>> getAllNotes() async {
    return <_i3.NoteModel>[];
  }

  @override
  Future<List<_i3.NoteModel>> getNotesByMode(String mode) async {
    return <_i3.NoteModel>[];
  }

  @override
  Future<void> saveNote(_i3.NoteModel? note) async {
    // Mock implementation - do nothing
  }

  @override
  Future<void> deleteNote(String? id) async {
    // Mock implementation - do nothing
  }

  @override
  Future<_i3.NoteModel?> getNoteById(String? id) async {
    return null;
  }

  @override
  Future<List<_i3.NoteModel>> searchNotes(String query, {String? mode}) async {
    return <_i3.NoteModel>[];
  }

  @override
  Future<void> archiveNote(String id) async {
    // Mock implementation - do nothing
  }

  @override
  Future<void> toggleFavorite(String id) async {
    // Mock implementation - do nothing
  }

  @override
  Future<List<_i3.NoteModel>> getNotesByTag(String tag) async {
    return <_i3.NoteModel>[];
  }

  @override
  Future<void> deleteMultipleNotes(List<String> ids) async {
    // Mock implementation - do nothing
  }

  @override
  Future<void> archiveMultipleNotes(List<String> ids) async {
    // Mock implementation - do nothing
  }

  @override
  Future<List<_i3.NoteModel>> getRecentNotes({int days = 7}) async {
    return <_i3.NoteModel>[];
  }

  @override
  Future<List<String>> getAllTags() async {
    return <String>[];
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    return <String, dynamic>{
      'total': 0,
      'work': 0,
      'personal': 0,
      'archived': 0,
      'favorites': 0,
      'tags': 0,
    };
  }

  @override
  Future<List<_i3.NoteModel>> exportAllNotes() async {
    return <_i3.NoteModel>[];
  }

  @override
  Future<void> importNotes(List<_i3.NoteModel> notes) async {
    // Mock implementation - do nothing
  }

  @override
  Future<void> clearAllNotes() async {
    // Mock implementation - do nothing
  }
}
