// ==========================================
// lib/data/services/note_sync_service.dart
// ==========================================
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note_model.dart';

/// Service to sync notes between local Hive storage and Firestore cloud
class NoteSyncService {
  static const String _notesCollection = 'notes';
  static const Duration _syncInterval = Duration(seconds: 30);
  
  static NoteSyncService? _instance;
  static NoteSyncService get instance {
    _instance ??= NoteSyncService._();
    return _instance!;
  }

  NoteSyncService._();

  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  StreamSubscription<QuerySnapshot>? _cloudNotesSubscription;

  /// Initialize sync service - starts automatic sync
  Future<void> initialize() async {
    try {
      debugPrint('🔄 NoteSyncService: Initializing...');
      
      // Initial sync
      await syncNotes();
      
      // Setup automatic sync interval
      _syncTimer = Timer.periodic(_syncInterval, (_) => syncNotes());
      
      // Listen to real-time Firestore changes
      _setupCloudListener();
      
      debugPrint('✅ NoteSyncService: Initialized with ${_syncInterval.inSeconds}s interval');
    } catch (e) {
      debugPrint('❌ NoteSyncService: Initialization failed: $e');
    }
  }

  /// Setup real-time listener for cloud changes
  void _setupCloudListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ NoteSyncService: Cannot setup cloud listener - no user logged in');
      return;
    }

    _cloudNotesSubscription = FirebaseFirestore.instance
        .collection(_notesCollection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        // Ignore changes caused by our own sync
        if (_isSyncing) {
          debugPrint('⏭️ NoteSyncService: Ignoring cloud changes during active sync');
          return;
        }
        
        debugPrint('🔔 NoteSyncService: Cloud changes detected (${snapshot.docChanges.length} changes)');
        // Trigger sync when cloud changes are detected from other devices
        syncNotes();
      },
      onError: (error) {
        debugPrint('❌ NoteSyncService: Cloud listener error: $error');
      },
    );
  }

  /// Main sync function - merges local and cloud notes
  Future<void> syncNotes() async {
    if (_isSyncing) {
      debugPrint('⏭️ NoteSyncService: Sync already in progress, skipping');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ NoteSyncService: Cannot sync - no user logged in');
      return;
    }

    _isSyncing = true;
    debugPrint('🔄 NoteSyncService: Starting sync for user ${user.uid}...');

    try {
      // 1. Get local notes from Hive
      final notesBox = await Hive.openBox<Note>('notes');
      final localNotes = notesBox.values.toList();
      debugPrint('📱 NoteSyncService: Found ${localNotes.length} local notes');

      // 2. Get cloud notes from Firestore
      final cloudSnapshot = await FirebaseFirestore.instance
          .collection(_notesCollection)
          .where('userId', isEqualTo: user.uid)
          .get();
      
      final cloudNotes = cloudSnapshot.docs
          .map((doc) => _noteFromFirestore(doc))
          .whereType<Note>()
          .toList();
      debugPrint('☁️ NoteSyncService: Found ${cloudNotes.length} cloud notes');

      // 3. Merge notes using conflict resolution
      final mergedNotes = _mergeNotes(localNotes, cloudNotes);
      debugPrint('🔀 NoteSyncService: Merged into ${mergedNotes.length} notes');

      // 4. Update Firestore with merged notes
      final batch = FirebaseFirestore.instance.batch();
      for (final note in mergedNotes) {
        final docRef = FirebaseFirestore.instance
            .collection(_notesCollection)
            .doc(note.id);
        batch.set(docRef, _noteToFirestore(note, user.uid), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('☁️ NoteSyncService: Uploaded ${mergedNotes.length} notes to Firestore');

      // 5. Update local Hive with merged notes (WITHOUT clearing - just update/add)
      for (final note in mergedNotes) {
        await notesBox.put(note.id, note);
      }
      debugPrint('📱 NoteSyncService: Updated local Hive with ${mergedNotes.length} notes');

      _lastSyncTime = DateTime.now();
      debugPrint('✅ NoteSyncService: Sync completed at ${_lastSyncTime}');
    } catch (e, stackTrace) {
      debugPrint('❌ NoteSyncService: Sync failed: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isSyncing = false;
    }
  }

  /// Merge local and cloud notes with conflict resolution
  /// Strategy: Prefer the note with the latest updatedAt timestamp
  List<Note> _mergeNotes(List<Note> localNotes, List<Note> cloudNotes) {
    final merged = <String, Note>{};

    // Add cloud notes first
    for (final note in cloudNotes) {
      merged[note.id] = note;
    }

    // Add/update with local notes (prefer newer timestamps)
    for (final localNote in localNotes) {
      final cloudNote = merged[localNote.id];
      
      if (cloudNote == null) {
        // New local note not in cloud
        merged[localNote.id] = localNote;
      } else {
        // Conflict: choose newer version
        if (localNote.updatedAt.isAfter(cloudNote.updatedAt)) {
          merged[localNote.id] = localNote;
          debugPrint('  ↪️ Preferring local version of note ${localNote.id} (newer)');
        } else {
          debugPrint('  ↪️ Keeping cloud version of note ${localNote.id} (newer)');
        }
      }
    }

    return merged.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Convert Firestore document to Note model
  Note? _noteFromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return Note(
        id: doc.id,
        title: data['title'] as String? ?? '',
        content: data['content'] as String? ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        color: data['color'] as String?,
        isArchived: data['isArchived'] as bool? ?? false,
        isFavorite: data['isFavorite'] as bool? ?? false,
        mode: data['mode'] as String? ?? 'personal',
        priority: data['priority'] as int? ?? 0,
        aiSummary: data['aiSummary'] as String?,
        attachments: (data['attachments'] as List<dynamic>?)?.cast<String>() ?? [],
        userId: data['userId'] as String?,
        reminderDate: (data['reminderDate'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      debugPrint('⚠️ NoteSyncService: Failed to parse note ${doc.id}: $e');
      return null;
    }
  }

  /// Convert Note model to Firestore document
  Map<String, dynamic> _noteToFirestore(Note note, String userId) {
    return {
      'userId': userId,
      'title': note.title,
      'content': note.content,
      'createdAt': Timestamp.fromDate(note.createdAt),
      'updatedAt': Timestamp.fromDate(note.updatedAt),
      'tags': note.tags,
      'color': note.color,
      'isArchived': note.isArchived,
      'isFavorite': note.isFavorite,
      'mode': note.mode,
      'priority': note.priority,
      'aiSummary': note.aiSummary,
      'attachments': note.attachments,
      'reminderDate': note.reminderDate != null ? Timestamp.fromDate(note.reminderDate!) : null,
    };
  }

  /// Manual sync trigger
  Future<void> forceSyncNow() async {
    debugPrint('🔄 NoteSyncService: Manual sync triggered');
    await syncNotes();
  }

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Dispose service and cleanup
  void dispose() {
    _syncTimer?.cancel();
    _cloudNotesSubscription?.cancel();
    _instance = null;
    debugPrint('🛑 NoteSyncService: Disposed');
  }
}
