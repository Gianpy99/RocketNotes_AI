// Simplified app providers for initial launch
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/note_repository.dart';
import '../../core/debug/debug_logger.dart';
import '../../features/rocketbook/ai_analysis/ai_service.dart';
import '../../features/rocketbook/ocr/ocr_service_real.dart';
import '../../core/services/openai_service.dart';

// AI Service Provider
final aiServiceProvider = Provider<AIService>((ref) {
  final service = AIService.instance;
  // Initialize with default configuration
  service.initialize();
  return service;
});

// OCR Service Provider
final ocrServiceProvider = Provider<OCRService>((ref) {
  final service = OCRService.instance;
  // Initialize OCR service
  service.initialize();
  return service;
});

// OpenAI Service Provider
final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService();
});

// Note Repository Provider
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

// App Mode Provider (work/personal)
final appModeProvider = StateNotifierProvider<AppModeNotifier, String>((ref) {
  return AppModeNotifier();
});

class AppModeNotifier extends StateNotifier<String> {
  AppModeNotifier() : super('personal');

  void setMode(String mode) {
    state = mode;
  }
}

// Notes Provider
final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<NoteModel>>>((ref) {
  final repository = ref.read(noteRepositoryProvider);
  return NotesNotifier(repository);
});

class NotesNotifier extends StateNotifier<AsyncValue<List<NoteModel>>> {
  final NoteRepository _repository;

  NotesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> saveNote(NoteModel note) async {
    try {
      DebugLogger().log('🔄 NotesNotifier: Starting to save note ${note.id}...');
      await _repository.saveNote(note);
      DebugLogger().log('💾 NotesNotifier: Note saved to repository, reloading notes...');
      await loadNotes(); // Reload after saving
      DebugLogger().log('✅ NotesNotifier: Save operation completed successfully');
    } catch (error, stackTrace) {
      DebugLogger().log('❌ NotesNotifier: Error saving note: $error');
      DebugLogger().log('Stack trace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addNote(NoteModel note) async {
    try {
      await _repository.saveNote(note);
      await loadNotes(); // Reload after saving
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _repository.deleteNote(id);
      await loadNotes(); // Reload after deleting
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<NoteModel?> getNoteById(String id) async {
    return await _repository.getNoteById(id);
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final note = await _repository.getNoteById(id);
      if (note != null) {
        final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
        await _repository.saveNote(updatedNote);
        await loadNotes();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> archiveNote(String id) async {
    try {
      final note = await _repository.getNoteById(id);
      if (note != null) {
        final updatedNote = note.copyWith(isArchived: !note.isArchived);
        await _repository.saveNote(updatedNote);
        await loadNotes();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Favorite Notes Provider
final favoriteNotesProvider = FutureProvider<List<NoteModel>>((ref) async {
  final repository = ref.read(noteRepositoryProvider);
  final allNotes = await repository.getAllNotes();
  return allNotes.where((note) => note.isFavorite).toList();
});

// Archived Notes Provider
final archivedNotesProvider = FutureProvider<List<NoteModel>>((ref) async {
  final repository = ref.read(noteRepositoryProvider);
  final allNotes = await repository.getAllNotes();
  return allNotes.where((note) => note.isArchived).toList();
});

// Recent Notes Provider
final recentNotesProvider = FutureProviderFamily<List<NoteModel>, int>((ref, days) async {
  final repository = ref.read(noteRepositoryProvider);
  final allNotes = await repository.getAllNotes();
  final cutoffDate = DateTime.now().subtract(Duration(days: days));
  return allNotes.where((note) => note.createdAt.isAfter(cutoffDate)).toList();
});

// Search Notes Provider
final searchNotesProvider = FutureProviderFamily<List<NoteModel>, String>((ref, query) async {
  final repository = ref.read(noteRepositoryProvider);
  return await repository.searchNotes(query);
});

// Theme Mode Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Loading State Provider
final loadingProvider = StateProvider<bool>((ref) => false);
