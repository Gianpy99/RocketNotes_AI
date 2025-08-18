// lib/presentation/providers/app_providers.dart (continued)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/services/nfc_service.dart';
import '../../data/services/deep_link_service.dart';

// Theme Mode Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  final Box settingsBox = Hive.box(AppConstants.settingsBox);

  void _loadThemeMode() {
    final savedMode = settingsBox.get(AppConstants.themeModeKey);
    if (savedMode != null) {
      state = ThemeMode.values[savedMode as int];
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    settingsBox.put(AppConstants.themeModeKey, mode.index);
  }
}

// App Mode Provider (work/personal)
final appModeProvider = StateNotifierProvider<AppModeNotifier, String>((ref) {
  return AppModeNotifier();
});

class AppModeNotifier extends StateNotifier<String> {
  AppModeNotifier() : super(AppConstants.workMode) {
    _loadMode();
  }

  final Box settingsBox = Hive.box(AppConstants.settingsBox);

  void _loadMode() {
    final savedMode = settingsBox.get(AppConstants.currentModeKey);
    if (savedMode != null) {
      state = savedMode as String;
    }
  }

  void setMode(String mode) {
    state = mode;
    settingsBox.put(AppConstants.currentModeKey, mode);
  }
}

// Note Repository Provider
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

// Notes Provider
final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<NoteModel>>>((ref) {
  return NotesNotifier(ref.read(noteRepositoryProvider));
});

class NotesNotifier extends StateNotifier<AsyncValue<List<NoteModel>>> {
  NotesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  final NoteRepository _repository;

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadNotesByMode(String mode) async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.getNotesByMode(mode);
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> saveNote(NoteModel note) async {
    try {
      await _repository.saveNote(note);
      await loadNotes();
    } catch (error) {
      print('Error saving note: $error');
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _repository.deleteNote(id);
      await loadNotes();
    } catch (error) {
      print('Error deleting note: $error');
    }
  }

  Future<void> searchNotes(String query) async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.searchNotes(query);
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// NFC Service Provider
final nfcServiceProvider = Provider<NfcService>((ref) {
  return NfcService();
});

// Deep Link Service Provider
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});
