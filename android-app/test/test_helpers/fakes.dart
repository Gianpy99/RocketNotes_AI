import 'package:pensieve/data/models/note_model.dart';
import 'package:pensieve/data/repositories/note_repository.dart';

class FakeNoteRepository implements NoteRepository {
  final List<NoteModel> notes;

  FakeNoteRepository([this.notes = const []]);

  @override
  Future<List<NoteModel>> getAllNotes() async => notes;

  @override
  Future<void> saveNote(NoteModel note) async {}

  @override
  Future<void> deleteNote(String id) async {}

  @override
  Future<NoteModel?> getNoteById(String id) async => notes.firstWhere((n) => n.id == id, orElse: () => null);

  @override
  Future<List<NoteModel>> searchNotes(String query) async => notes.where((n) => n.title.contains(query) || n.content.contains(query)).toList();
}
