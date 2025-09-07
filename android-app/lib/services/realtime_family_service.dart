import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../models/family.dart';
import '../models/family_member.dart';
import '../models/shared_note.dart';
import '../models/family_invitation.dart';
import '../models/note_permission.dart';

/// Service for managing real-time listeners for family data synchronization
class RealtimeFamilyService {
  final FirebaseFirestore _firestore;

  // Stream controllers for different data types
  final BehaviorSubject<List<Family>> _familiesController = BehaviorSubject<List<Family>>();
  final BehaviorSubject<List<FamilyMember>> _familyMembersController = BehaviorSubject<List<FamilyMember>>();
  final BehaviorSubject<List<SharedNote>> _sharedNotesController = BehaviorSubject<List<SharedNote>>();
  final BehaviorSubject<List<FamilyInvitation>> _invitationsController = BehaviorSubject<List<FamilyInvitation>>();
  final BehaviorSubject<List<NotePermission>> _notePermissionsController = BehaviorSubject<List<NotePermission>>();

  // Active listeners
  final Map<String, StreamSubscription> _activeListeners = {};

  // Connection status
  final BehaviorSubject<bool> _isConnectedController = BehaviorSubject<bool>.seeded(true);

  RealtimeFamilyService(this._firestore);

  // Public streams
  Stream<List<Family>> get families => _familiesController.stream;
  Stream<List<FamilyMember>> get familyMembers => _familyMembersController.stream;
  Stream<List<SharedNote>> get sharedNotes => _sharedNotesController.stream;
  Stream<List<FamilyInvitation>> get invitations => _invitationsController.stream;
  Stream<List<NotePermission>> get notePermissions => _notePermissionsController.stream;
  Stream<bool> get isConnected => _isConnectedController.stream;

  /// Initialize real-time listeners for a specific family
  Future<void> initializeFamilyListeners(String familyId) async {
    try {
      // Clear existing listeners for this family
      await _clearFamilyListeners(familyId);

      // Listen to family document changes
      _listenToFamilyDocument(familyId);

      // Listen to family members changes
      _listenToFamilyMembers(familyId);

      // Listen to shared notes changes
      _listenToSharedNotes(familyId);

      // Listen to invitations changes
      _listenToInvitations(familyId);

      // Listen to note permissions changes
      _listenToNotePermissions(familyId);

      debugPrint('✅ Initialized real-time listeners for family: $familyId');
    } catch (e) {
      debugPrint('❌ Failed to initialize family listeners: $e');
      rethrow;
    }
  }

  /// Listen to family document changes
  void _listenToFamilyDocument(String familyId) {
    final listenerKey = 'family_$familyId';
    final subscription = _firestore
        .collection('families')
        .doc(familyId)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              try {
                final family = Family.fromJson(doc.data()!..['id'] = doc.id);
                _familiesController.add([family]);
                debugPrint('📡 Family updated: ${family.name}');
              } catch (e) {
                debugPrint('❌ Error parsing family document: $e');
              }
            }
          },
          onError: (error) {
            debugPrint('❌ Family listener error: $error');
            _handleConnectionError();
          },
        );

    _activeListeners[listenerKey] = subscription;
  }

  /// Listen to family members changes
  void _listenToFamilyMembers(String familyId) {
    final listenerKey = 'members_$familyId';
    final subscription = _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final members = snapshot.docs
                  .map((doc) => FamilyMember.fromJson(doc.data()..['id'] = doc.id))
                  .toList();
              _familyMembersController.add(members);
              debugPrint('📡 Family members updated: ${members.length} members');
            } catch (e) {
              debugPrint('❌ Error parsing family members: $e');
            }
          },
          onError: (error) {
            debugPrint('❌ Family members listener error: $error');
            _handleConnectionError();
          },
        );

    _activeListeners[listenerKey] = subscription;
  }

  /// Listen to shared notes changes
  void _listenToSharedNotes(String familyId) {
    final listenerKey = 'shared_notes_$familyId';
    final subscription = _firestore
        .collection('shared_notes')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final notes = snapshot.docs
                  .map((doc) => SharedNote.fromJson(doc.data()..['id'] = doc.id))
                  .toList();
              _sharedNotesController.add(notes);
              debugPrint('📡 Shared notes updated: ${notes.length} notes');
            } catch (e) {
              debugPrint('❌ Error parsing shared notes: $e');
            }
          },
          onError: (error) {
            debugPrint('❌ Shared notes listener error: $error');
            _handleConnectionError();
          },
        );

    _activeListeners[listenerKey] = subscription;
  }

  /// Listen to invitations changes
  void _listenToInvitations(String familyId) {
    final listenerKey = 'invitations_$familyId';
    final subscription = _firestore
        .collection('invitations')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final invitations = snapshot.docs
                  .map((doc) => FamilyInvitation.fromJson(doc.data()..['id'] = doc.id))
                  .toList();
              _invitationsController.add(invitations);
              debugPrint('📡 Invitations updated: ${invitations.length} invitations');
            } catch (e) {
              debugPrint('❌ Error parsing invitations: $e');
            }
          },
          onError: (error) {
            debugPrint('❌ Invitations listener error: $error');
            _handleConnectionError();
          },
        );

    _activeListeners[listenerKey] = subscription;
  }

  /// Listen to note permissions changes
  void _listenToNotePermissions(String familyId) {
    final listenerKey = 'permissions_$familyId';
    final subscription = _firestore
        .collection('note_permissions')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final permissions = snapshot.docs
                  .map((doc) => NotePermission.fromJson(doc.data()..['id'] = doc.id))
                  .toList();
              _notePermissionsController.add(permissions);
              debugPrint('📡 Note permissions updated: ${permissions.length} permissions');
            } catch (e) {
              debugPrint('❌ Error parsing note permissions: $e');
            }
          },
          onError: (error) {
            debugPrint('❌ Note permissions listener error: $error');
            _handleConnectionError();
          },
        );

    _activeListeners[listenerKey] = subscription;
  }

  /// Listen to specific shared note changes (for collaboration)
  Stream<SharedNote?> listenToSharedNote(String sharedNoteId) {
    return _firestore
        .collection('shared_notes')
        .doc(sharedNoteId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            try {
              return SharedNote.fromJson(doc.data()!..['id'] = doc.id);
            } catch (e) {
              debugPrint('❌ Error parsing shared note: $e');
              return null;
            }
          }
          return null;
        });
  }

  /// Listen to collaboration sessions for a shared note
  Stream<List<Map<String, dynamic>>> listenToCollaborationSessions(String sharedNoteId) {
    return _firestore
        .collection('collaboration_sessions')
        .where('sharedNoteId', isEqualTo: sharedNoteId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
        });
  }

  /// Handle connection errors
  void _handleConnectionError() {
    _isConnectedController.add(false);

    // Attempt to reconnect after delay
    Future.delayed(const Duration(seconds: 5), () {
      _isConnectedController.add(true);
      debugPrint('🔄 Attempting to reconnect real-time listeners...');
    });
  }

  /// Clear all listeners for a specific family
  Future<void> _clearFamilyListeners(String familyId) async {
    final keysToRemove = _activeListeners.keys
        .where((key) => key.contains(familyId))
        .toList();

    for (final key in keysToRemove) {
      await _activeListeners[key]?.cancel();
      _activeListeners.remove(key);
    }

    debugPrint('🧹 Cleared listeners for family: $familyId');
  }

  /// Clear all active listeners
  Future<void> clearAllListeners() async {
    for (final subscription in _activeListeners.values) {
      await subscription.cancel();
    }
    _activeListeners.clear();

    // Reset stream controllers
    _familiesController.add([]);
    _familyMembersController.add([]);
    _sharedNotesController.add([]);
    _invitationsController.add([]);
    _notePermissionsController.add([]);

    debugPrint('🧹 Cleared all real-time listeners');
  }

  /// Get current data from streams
  List<Family> get currentFamilies => _familiesController.valueOrNull ?? [];
  List<FamilyMember> get currentFamilyMembers => _familyMembersController.valueOrNull ?? [];
  List<SharedNote> get currentSharedNotes => _sharedNotesController.valueOrNull ?? [];
  List<FamilyInvitation> get currentInvitations => _invitationsController.valueOrNull ?? [];
  List<NotePermission> get currentNotePermissions => _notePermissionsController.valueOrNull ?? [];

  /// Dispose of all resources
  Future<void> dispose() async {
    await clearAllListeners();

    await _familiesController.close();
    await _familyMembersController.close();
    await _sharedNotesController.close();
    await _invitationsController.close();
    await _notePermissionsController.close();
    await _isConnectedController.close();

    debugPrint('🗑️ Disposed RealtimeFamilyService');
  }

  /// Check if listeners are active for a family
  bool hasActiveListeners(String familyId) {
    return _activeListeners.keys.any((key) => key.contains(familyId));
  }

  /// Get listener count for debugging
  int get activeListenerCount => _activeListeners.length;

  /// Force refresh all data (useful for manual sync)
  Future<void> forceRefresh(String familyId) async {
    try {
      // Reinitialize listeners to force fresh data
      await initializeFamilyListeners(familyId);
      debugPrint('🔄 Forced refresh for family: $familyId');
    } catch (e) {
      debugPrint('❌ Failed to force refresh: $e');
      rethrow;
    }
  }
}
