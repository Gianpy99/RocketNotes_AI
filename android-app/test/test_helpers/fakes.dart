import 'package:pensieve/data/models/note_model.dart';
import 'package:pensieve/data/repositories/note_repository.dart';
import 'package:hive/hive.dart';

class FakeNoteRepository implements NoteRepository {
  final List<NoteModel> notes;

  FakeNoteRepository([this.notes = const []]);

  @override
  Box<NoteModel> get notesBox => throw UnimplementedError('Fake repository does not use Hive box');

  @override
  Future<List<NoteModel>> getAllNotes() async => notes;

  @override
  Future<void> saveNote(NoteModel note) async {}

  @override
  Future<void> deleteNote(String id) async {}

  @override
  Future<NoteModel?> getNoteById(String id) async => 
    notes.cast<NoteModel?>().firstWhere((n) => n?.id == id, orElse: () => null);

  @override
  Future<List<NoteModel>> searchNotes(String query, {String? mode}) async => 
    notes.where((n) => 
      (n.title.contains(query) || n.content.contains(query)) &&
      (mode == null || n.mode == mode)
    ).toList();

  @override
  Future<void> archiveNote(String id) async {}

  @override
  Future<void> archiveMultipleNotes(List<String> ids) async {}

  @override
  Future<void> deleteMultipleNotes(List<String> ids) async {}

  @override
  Future<void> clearAllNotes() async {}

  @override
  Future<List<NoteModel>> getRecentNotes({int days = 7}) async => 
    notes.take(10).toList();

  @override
  Future<List<NoteModel>> getNotesByMode(String mode) async => 
    notes.where((n) => n.mode == mode).toList();

  @override
  Future<List<NoteModel>> getNotesByTag(String tag) async => 
    notes.where((n) => n.tags.contains(tag)).toList();

  @override
  Future<List<String>> getAllTags() async {
    final tags = <String>{};
    for (final note in notes) {
      tags.addAll(note.tags);
    }
    return tags.toList();
  }

  @override
  Future<void> toggleFavorite(String id) async {}

  @override
  Future<Map<String, dynamic>> getStatistics() async => {
    'total': notes.length,
    'work': notes.where((n) => n.mode == 'work').length,
    'personal': notes.where((n) => n.mode == 'personal').length,
    'archived': notes.where((n) => n.isArchived).length,
  };

  @override
  Future<List<NoteModel>> exportAllNotes() async => notes;

  @override
  Future<void> importNotes(List<NoteModel> notes) async {}
}
