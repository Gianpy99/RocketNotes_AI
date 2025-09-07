// lib/data/repositories/hybrid_note_repository.dart
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/note_model.dart';
import '../../core/services/firebase_service.dart';
import '../../core/debug/debug_logger.dart';
import '../../core/constants/app_constants.dart';

class HybridNoteRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final Connectivity _connectivity = Connectivity();

  Box<NoteModel>? _notesBox;

  Box<NoteModel> get notesBox {
    if (_notesBox == null || !_notesBox!.isOpen) {
      try {
        _notesBox = Hive.box<NoteModel>(AppConstants.notesBox);
      } catch (e) {
        throw Exception('Notes box not found. Make sure Hive is properly initialized: $e');
      }
    }
    return _notesBox!;
  }

  Future<bool> _isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && results.first != ConnectivityResult.none;
  }

  Future<List<NoteModel>> getAllNotes() async {
    try {
      // Try to get notes from Supabase if online
      if (await _isOnline() && _firebaseService.currentUser != null) {
        final cloudNotes = await _firebaseService.getNotes();
        // Sync cloud notes to local storage
        await _syncNotesToLocal(cloudNotes);
        return cloudNotes;
      } else {
        // Fall back to local storage
        return await _getLocalNotes();
      }
    } catch (e) {
      DebugLogger().log('❌ Error getting notes: $e');
      // Fall back to local storage on error
      return await _getLocalNotes();
    }
  }

  Future<List<NoteModel>> _getLocalNotes() async {
    final notes = notesBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    DebugLogger().log('📋 Repository: Loaded ${notes.length} local notes');
    return notes;
  }

  Future<void> _syncNotesToLocal(List<NoteModel> cloudNotes) async {
    for (final note in cloudNotes) {
      await notesBox.put(note.id, note);
    }
    DebugLogger().log('✅ Synced ${cloudNotes.length} notes from cloud to local');
  }

  Future<List<NoteModel>> getNotesByMode(String mode) async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.mode == mode).toList();
  }

  Future<NoteModel?> getNoteById(String id) async {
    // Try local first for faster access
    final localNote = notesBox.get(id);
    if (localNote != null) {
      return localNote;
    }

    // If not found locally and online, try cloud
    if (await _isOnline() && _firebaseService.currentUser != null) {
      try {
        final cloudNotes = await _firebaseService.getNotes();
        final cloudNote = cloudNotes.where((note) => note.id == id).firstOrNull;
        if (cloudNote != null) {
          // Cache in local storage
          await notesBox.put(cloudNote.id, cloudNote);
          return cloudNote;
        }
      } catch (e) {
        DebugLogger().log('❌ Error fetching note from cloud: $e');
      }
    }

    return null;
  }

  Future<void> saveNote(NoteModel note) async {
    try {
      // Save to local storage first (for immediate UI update)
      await notesBox.put(note.id, note);

      // If online, also save to cloud
      if (await _isOnline() && _firebaseService.currentUser != null) {
        if (await _isNoteInCloud(note.id)) {
          await _firebaseService.updateNote(note);
        } else {
          await _firebaseService.createNote(note);
        }
        DebugLogger().log('✅ Note synced to cloud: ${note.title}');
      } else {
        DebugLogger().log('📱 Note saved locally (offline): ${note.title}');
      }
    } catch (e) {
      DebugLogger().log('❌ Error saving note: $e');
      // Still save locally even if cloud sync fails
      await notesBox.put(note.id, note);
    }
  }

  Future<bool> _isNoteInCloud(String noteId) async {
    try {
      final cloudNotes = await _firebaseService.getNotes();
      return cloudNotes.any((note) => note.id == noteId);
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      // Delete from local storage
      await notesBox.delete(noteId);

      // If online, also delete from cloud
      if (await _isOnline() && _firebaseService.currentUser != null) {
        await _firebaseService.deleteNote(noteId);
        DebugLogger().log('✅ Note deleted from cloud: $noteId');
      } else {
        DebugLogger().log('📱 Note deleted locally (offline): $noteId');
      }
    } catch (e) {
      DebugLogger().log('❌ Error deleting note: $e');
      // Still delete locally even if cloud sync fails
      await notesBox.delete(noteId);
    }
  }

  Future<void> syncNotes() async {
    if (!await _isOnline() || _firebaseService.currentUser == null) {
      DebugLogger().log('📱 Skipping sync - offline or not authenticated');
      return;
    }

    try {
      DebugLogger().log('🔄 Starting notes synchronization...');

      // Get all cloud notes
      final cloudNotes = await _firebaseService.getNotes();

      // Get all local notes
      final localNotes = notesBox.values.toList();

      // Sync cloud to local
      for (final cloudNote in cloudNotes) {
        final localNote = localNotes.where((note) => note.id == cloudNote.id).firstOrNull;

        if (localNote == null) {
          // New note from cloud
          await notesBox.put(cloudNote.id, cloudNote);
          DebugLogger().log('📥 Synced new note from cloud: ${cloudNote.title}');
        } else if (cloudNote.updatedAt.isAfter(localNote.updatedAt)) {
          // Cloud version is newer
          await notesBox.put(cloudNote.id, cloudNote);
          DebugLogger().log('🔄 Updated local note from cloud: ${cloudNote.title}');
        } else if (localNote.updatedAt.isAfter(cloudNote.updatedAt)) {
          // Local version is newer
          await _firebaseService.updateNote(localNote);
          DebugLogger().log('🔄 Updated cloud note from local: ${localNote.title}');
        }
      }

      // Find local notes that don't exist in cloud (new local notes)
      for (final localNote in localNotes) {
        final existsInCloud = cloudNotes.any((note) => note.id == localNote.id);
        if (!existsInCloud) {
          await _firebaseService.createNote(localNote);
          DebugLogger().log('📤 Synced new local note to cloud: ${localNote.title}');
        }
      }

      DebugLogger().log('✅ Notes synchronization completed');
    } catch (e) {
      DebugLogger().log('❌ Error during notes synchronization: $e');
    }
  }
}
