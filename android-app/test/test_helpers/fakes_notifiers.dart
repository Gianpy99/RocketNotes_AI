import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pensieve/data/models/note_model.dart';

class FakeEmptyNotesNotifier extends StateNotifier<AsyncValue<List<NoteModel>>> {
  FakeEmptyNotesNotifier() : super(const AsyncValue.data(<NoteModel>[]));
}
