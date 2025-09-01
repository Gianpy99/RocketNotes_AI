// Automatically generated mock file
// ignore_for_file: non_constant_identifier_names, prefer_const_constructors_in_immutables

import 'package:mockito/mockito.dart' as _i1;
import '../../../android-app/lib/data/repositories/note_repository.dart' as _i2;
import '../../../android-app/lib/data/models/note_model.dart' as _i3;

class MockNoteRepository extends _i1.Mock implements _i2.NoteRepository {
  @override
  Future<List<_i3.NoteModel>> getAllNotes() => (super.noSuchMethod(
        Invocation.method(#getAllNotes, []),
        returnValue: Future<List<_i3.NoteModel>>.value(<_i3.NoteModel>[]),
      ) as Future<List<_i3.NoteModel>>);

  @override
  Future<void> saveNote(_i3.NoteModel? note) => (super.noSuchMethod(
        Invocation.method(#saveNote, [note]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>);

  @override
  Future<void> deleteNote(String? id) => (super.noSuchMethod(
        Invocation.method(#deleteNote, [id]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>);

  @override
  Future<_i3.NoteModel?> getNoteById(String? id) => (super.noSuchMethod(
        Invocation.method(#getNoteById, [id]),
        returnValue: Future<_i3.NoteModel?>.value(),
      ) as Future<_i3.NoteModel?>);

  @override
  Stream<List<_i3.NoteModel>> watchNotes() => (super.noSuchMethod(
        Invocation.method(#watchNotes, []),
        returnValue: const Stream<List<_i3.NoteModel>>.empty(),
      ) as Stream<List<_i3.NoteModel>>);
}
