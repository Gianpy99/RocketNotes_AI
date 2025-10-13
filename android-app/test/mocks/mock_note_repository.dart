import 'package:pensieve/data/models/note_model.dart';
import 'package:pensieve/data/repositories/note_repository.dart';

class MockNoteRepository extends NoteRepository {
  final List<NoteModel> _notes;

  MockNoteRepository([List<NoteModel>? notes]) : _notes = notes ?? [];

  // Helper method for tests to add notes easily
  void addNote(NoteModel note) {
    _notes.add(note);
  }

  @override
  Future<List<NoteModel>> getAllNotes() async => _notes.where((n) => !n.isArchived).toList();

  @override
  Future<List<NoteModel>> getNotesByMode(String mode) async {
    return _notes.where((n) => n.mode == mode && !n.isArchived).toList();
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    for (final n in _notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  @override
  Future<void> saveNote(NoteModel note) async {
    final existing = _notes.indexWhere((n) => n.id == note.id);
    if (existing >= 0) _notes[existing] = note;
    else _notes.add(note);
  }

  @override
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
  }

  @override
  Future<List<NoteModel>> searchNotes(String query, {String? mode}) async {
    return _notes.where((n) {
      final matchesQuery = n.title.toLowerCase().contains(query.toLowerCase()) || 
                          n.content.toLowerCase().contains(query.toLowerCase());
      final matchesMode = mode == null || n.mode == mode;
      return matchesQuery && matchesMode && !n.isArchived;
    }).toList();
  }

  // Additional methods for filtering
  Future<List<NoteModel>> getFavoriteNotes() async {
    return _notes.where((n) => n.isFavorite && !n.isArchived).toList();
  }

  Future<List<NoteModel>> getArchivedNotes() async {
    return _notes.where((n) => n.isArchived).toList();
  }

  @override
  Future<void> archiveNote(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final updated = note.copyWith(isArchived: true);
      await saveNote(updated);
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final updated = note.copyWith(isFavorite: !note.isFavorite);
      await saveNote(updated);
    }
  }
}
