// lib/data/services/sync_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/note_model.dart';
import '../repositories/note_repository.dart';

class SyncService {
  final ApiService apiService;
  final NoteRepository noteRepository;
  final Connectivity _connectivity = Connectivity();
  
  SyncService({required this.apiService, required this.noteRepository});
  
  Stream<ConnectivityResult> get connectivityStream => 
      _connectivity.onConnectivityChanged;
  
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  Future<void> syncNotes() async {
    if (!await isOnline) return;
    
    try {
      // Fetch server notes
      final serverNotes = await apiService.fetchNotes();
      
      // Get local notes
      final localNotes = await noteRepository.getAllNotes();
      
      // Merge and resolve conflicts
      final mergedNotes = await _mergeNotes(localNotes, serverNotes);
      
      // Save merged notes locally
      for (final note in mergedNotes) {
        await noteRepository.saveNote(note);
      }
      
      debugPrint('Sync completed successfully');
    } catch (e) {
      debugPrint('Sync failed: $e');
      rethrow;
    }
  }
  
  Future<List<NoteModel>> _mergeNotes(
    List<NoteModel> localNotes, 
    List<NoteModel> serverNotes
  ) async {
    final Map<String, NoteModel> merged = {};
    
    // Add server notes
    for (final note in serverNotes) {
      merged[note.id] = note;
    }
    
    // Add local notes, preferring newer versions
    for (final localNote in localNotes) {
      final serverNote = merged[localNote.id];
      if (serverNote == null || 
          localNote.updatedAt.isAfter(serverNote.updatedAt)) {
        merged[localNote.id] = localNote;
        // Upload to server if local is newer
        try {
          await apiService.updateNote(localNote);
        } catch (e) {
          debugPrint('Failed to upload note ${localNote.id}: $e');
        }
      }
    }
    
    return merged.values.toList();
  }
  
  Future<void> createNoteWithSync(NoteModel note) async {
    // Save locally first
    await noteRepository.saveNote(note);
    
    // Sync to server if online
    if (await isOnline) {
      try {
        await apiService.createNote(note);
      } catch (e) {
        debugPrint('Failed to sync new note: $e');
        // Note is still saved locally
      }
    }
  }
  
  Future<void> updateNoteWithSync(NoteModel note) async {
    // Update locally first
    await noteRepository.saveNote(note);
    
    // Sync to server if online
    if (await isOnline) {
      try {
        await apiService.updateNote(note);
      } catch (e) {
        debugPrint('Failed to sync updated note: $e');
      }
    }
  }
  
  Future<void> deleteNoteWithSync(String noteId) async {
    // Delete locally first
    await noteRepository.deleteNote(noteId);
    
    // Sync to server if online
    if (await isOnline) {
      try {
        await apiService.deleteNote(noteId);
      } catch (e) {
        debugPrint('Failed to sync note deletion: $e');
      }
    }
  }
}
