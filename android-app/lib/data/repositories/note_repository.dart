// lib/data/repositories/note_repository.dart
import 'package:hive/hive.dart';
import '../models/note_model.dart';

class NoteRepository {
  final Box notesBox = Hive.box('notes');

  Future<List<NoteModel>> getAllNotes() async {
    return notesBox.values.cast<NoteModel>().toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<NoteModel>> getNotesByMode(String mode) async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.mode == mode).toList();
  }

  Future<NoteModel?> getNoteById(String id) async {
    return notesBox.get(id) as NoteModel?;
  }

  Future<void> saveNote(NoteModel note) async {
    await notesBox.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await notesBox.delete(id);
  }

  Future<List<NoteModel>> searchNotes(String query) async {
    final allNotes = await getAllNotes();
    final lowercaseQuery = query.toLowerCase();
    
    return allNotes.where((note) {
      return note.title.toLowerCase().contains(lowercaseQuery) ||
             note.content.toLowerCase().contains(lowercaseQuery) ||
             note.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }
}
