/// Shared Notes Repository
///
/// Data access layer for shared notes operations.
/// Handles all database interactions for shared notes, permissions, and collaboration.
/// Uses Firebase Firestore as the primary data store.
///
/// This repository follows the repository pattern to abstract data access
/// and provide a clean interface for the service layer.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/shared_note.dart';
import '../../../models/shared_note_comment.dart';
import '../../../models/note_permission.dart';

class SharedNotesRepository {
  final FirebaseFirestore _firestore;

  // Collection references
  static const String sharedNotesCollection = 'shared_notes';
  static const String permissionsCollection = 'note_permissions';
  static const String collaborationSessionsCollection = 'collaboration_sessions';
  static const String commentsCollection = 'shared_note_comments';

  SharedNotesRepository(this._firestore);

  // Shared Notes CRUD Operations

  /// Creates a new shared note
  Future<SharedNote> createSharedNote({
    required String noteId,
    required String familyId,
    required String sharedBy,
    required String title,
    required NotePermission permission,
    String? description,
    bool requiresApproval = false,
    DateTime? expiresAt,
    bool allowCollaboration = false,
  }) async {
    final sharedNoteId = _firestore.collection(sharedNotesCollection).doc().id;

    final sharedNote = SharedNote(
      id: sharedNoteId,
      noteId: noteId,
      familyId: familyId,
      sharedBy: sharedBy,
      sharedAt: DateTime.now(),
      title: title,
      permission: permission,
      description: description,
      requiresApproval: requiresApproval,
      status: requiresApproval ? SharingStatus.pending : SharingStatus.approved,
      expiresAt: expiresAt,
      allowCollaboration: allowCollaboration,
      updatedAt: DateTime.now(),
      version: 1,
    );

    await _firestore.collection(sharedNotesCollection).doc(sharedNoteId).set(sharedNote.toJson());

    return sharedNote;
  }

  /// Gets a shared note by ID
  Future<SharedNote?> getSharedNote(String sharedNoteId) async {
    final doc = await _firestore.collection(sharedNotesCollection).doc(sharedNoteId).get();
    if (!doc.exists) return null;

    return SharedNote.fromJson(doc.data()!);
  }

  /// Gets a shared note by original note ID and family ID
  Future<SharedNote?> getSharedNoteByNoteId(String noteId, String familyId) async {
    final snapshot = await _firestore
        .collection(sharedNotesCollection)
        .where('noteId', isEqualTo: noteId)
        .where('familyId', isEqualTo: familyId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return SharedNote.fromJson(snapshot.docs.first.data());
  }

  /// Gets all shared notes for a family
  Future<List<SharedNote>> getSharedNotesForFamily(String familyId) async {
    final snapshot = await _firestore
        .collection(sharedNotesCollection)
        .where('familyId', isEqualTo: familyId)
        .where('status', isEqualTo: SharingStatus.approved.name)
        .get();

    return snapshot.docs
        .map((doc) => SharedNote.fromJson(doc.data()))
        .where((note) => note.expiresAt == null || note.expiresAt!.isAfter(DateTime.now()))
        .toList();
  }

  /// Gets shared notes by status
  Future<List<SharedNote>> getSharedNotesByStatus(String familyId, SharingStatus status) async {
    final snapshot = await _firestore
        .collection(sharedNotesCollection)
        .where('familyId', isEqualTo: familyId)
        .where('status', isEqualTo: status.name)
        .get();

    return snapshot.docs.map((doc) => SharedNote.fromJson(doc.data())).toList();
  }

  /// Gets shared notes by user
  Future<List<SharedNote>> getSharedNotesByUser(String userId) async {
    final snapshot = await _firestore
        .collection(sharedNotesCollection)
        .where('sharedBy', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => SharedNote.fromJson(doc.data())).toList();
  }

  /// Updates a shared note
  Future<void> updateSharedNote(
    String sharedNoteId, {
    String? title,
    String? description,
    NotePermission? permission,
    DateTime? expiresAt,
    bool? allowCollaboration,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (permission != null) updates['permission'] = permission.toJson();
    if (expiresAt != null) updates['expiresAt'] = expiresAt.toIso8601String();
    if (allowCollaboration != null) updates['allowCollaboration'] = allowCollaboration;

    await _firestore.collection(sharedNotesCollection).doc(sharedNoteId).update(updates);
  }

  /// Updates shared note status
  Future<void> updateSharedNoteStatus(
    String sharedNoteId,
    SharingStatus status, {
    String? approvedBy,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (approvedBy != null) {
      updates['approvedBy'] = approvedBy;
      updates['approvedAt'] = DateTime.now().toIso8601String();
    }

    await _firestore.collection(sharedNotesCollection).doc(sharedNoteId).update(updates);
  }

  /// Deletes a shared note
  Future<void> deleteSharedNote(String sharedNoteId) async {
    // Delete all permissions first
    await removeAllPermissionsForSharedNote(sharedNoteId);

    // Delete the shared note
    await _firestore.collection(sharedNotesCollection).doc(sharedNoteId).delete();
  }

  // Permission Management

  /// Creates a permission for a shared note
  Future<NotePermission> createPermission(NotePermission permission) async {
    final permissionId = _firestore.collection(permissionsCollection).doc().id;

    final permissionWithId = permission.copyWith(id: permissionId);

    await _firestore.collection(permissionsCollection).doc(permissionId).set(permissionWithId.toJson());

    return permissionWithId;
  }

  /// Gets permissions for a shared note
  Future<List<NotePermission>> getPermissionsForSharedNote(String sharedNoteId) async {
    final snapshot = await _firestore
        .collection(permissionsCollection)
        .where('sharedNoteId', isEqualTo: sharedNoteId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => NotePermission.fromJson(doc.data())).toList();
  }

  /// Gets permission for a specific user on a shared note
  Future<NotePermission?> getPermissionForUser(String sharedNoteId, String userId) async {
    final snapshot = await _firestore
        .collection(permissionsCollection)
        .where('sharedNoteId', isEqualTo: sharedNoteId)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return NotePermission.fromJson(snapshot.docs.first.data());
  }

  /// Updates permissions for a user on a shared note
  Future<void> updateMemberPermissions(
    String sharedNoteId,
    String userId,
    NotePermission newPermissions,
  ) async {
    final existingPermission = await getPermissionForUser(sharedNoteId, userId);
    if (existingPermission == null) {
      // Create new permission if it doesn't exist
      await createPermission(newPermissions);
      return;
    }

    final updates = <String, dynamic>{};

    if (newPermissions.canView != existingPermission.canView) {
      updates['canView'] = newPermissions.canView;
    }
    if (newPermissions.canEdit != existingPermission.canEdit) {
      updates['canEdit'] = newPermissions.canEdit;
    }
    if (newPermissions.canComment != existingPermission.canComment) {
      updates['canComment'] = newPermissions.canComment;
    }
    if (newPermissions.canDelete != existingPermission.canDelete) {
      updates['canDelete'] = newPermissions.canDelete;
    }
    if (newPermissions.canShare != existingPermission.canShare) {
      updates['canShare'] = newPermissions.canShare;
    }
    if (newPermissions.canExport != existingPermission.canExport) {
      updates['canExport'] = newPermissions.canExport;
    }
    if (newPermissions.canInviteCollaborators != existingPermission.canInviteCollaborators) {
      updates['canInviteCollaborators'] = newPermissions.canInviteCollaborators;
    }
    if (newPermissions.receiveNotifications != existingPermission.receiveNotifications) {
      updates['receiveNotifications'] = newPermissions.receiveNotifications;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection(permissionsCollection).doc(existingPermission.id).update(updates);
    }
  }

  /// Removes all permissions for a shared note
  Future<void> removeAllPermissionsForSharedNote(String sharedNoteId) async {
    final permissions = await getPermissionsForSharedNote(sharedNoteId);

    for (final permission in permissions) {
      await _firestore.collection(permissionsCollection).doc(permission.id).delete();
    }
  }

  /// Deactivates a user's permission for a shared note
  Future<void> deactivatePermission(String sharedNoteId, String userId) async {
    final permission = await getPermissionForUser(sharedNoteId, userId);
    if (permission != null) {
      await _firestore.collection(permissionsCollection).doc(permission.id).update({
        'isActive': false,
      });
    }
  }

  // Collaboration Management

  /// Creates a collaboration session for a shared note
  Future<String> createCollaborationSession(String sharedNoteId) async {
    final sessionId = _firestore.collection(collaborationSessionsCollection).doc().id;

    await _firestore.collection(sharedNotesCollection).doc(sharedNoteId).update({
      'collaborationSessionId': sessionId,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await _firestore.collection(collaborationSessionsCollection).doc(sessionId).set({
      'id': sessionId,
      'sharedNoteId': sharedNoteId,
      'startedAt': DateTime.now().toIso8601String(),
      'activeUsers': [],
      'isActive': true,
    });

    return sessionId;
  }

  /// Ends a collaboration session
  Future<void> endCollaborationSession(String sharedNoteId) async {
    final sharedNote = await getSharedNote(sharedNoteId);
    if (sharedNote?.collaborationSessionId != null) {
      await _firestore.collection(collaborationSessionsCollection).doc(sharedNote!.collaborationSessionId!).update({
        'endedAt': DateTime.now().toIso8601String(),
        'isActive': false,
      });

      await _firestore.collection(sharedNotesCollection).doc(sharedNoteId).update({
        'collaborationSessionId': null,
        'activeViewers': [],
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Updates active viewers for a shared note
  Future<void> updateActiveViewers(String sharedNoteId, List<String> viewerUserIds) async {
    await _firestore.collection(sharedNotesCollection).doc(sharedNoteId).update({
      'activeViewers': viewerUserIds,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Updates last accessed time for a permission
  Future<void> updatePermissionLastAccessed(String permissionId) async {
    await _firestore.collection(permissionsCollection).doc(permissionId).update({
      'lastAccessedAt': DateTime.now().toIso8601String(),
    });
  }

  // Utility Methods

  /// Checks if a shared note has expired
  Future<bool> isSharedNoteExpired(String sharedNoteId) async {
    final sharedNote = await getSharedNote(sharedNoteId);
    if (sharedNote == null) return true;

    return sharedNote.expiresAt != null && sharedNote.expiresAt!.isBefore(DateTime.now());
  }

  /// Gets shared notes that have expired
  Future<List<SharedNote>> getExpiredSharedNotes(String familyId) async {
    final allNotes = await getSharedNotesForFamily(familyId);
    return allNotes.where((note) => note.expiresAt != null && note.expiresAt!.isBefore(DateTime.now())).toList();
  }

  /// Cleans up expired shared notes and their permissions
  Future<void> cleanupExpiredSharedNotes(String familyId) async {
    final expiredNotes = await getExpiredSharedNotes(familyId);

    for (final note in expiredNotes) {
      await updateSharedNoteStatus(note.id, SharingStatus.expired);
      await removeAllPermissionsForSharedNote(note.id);
    }
  }

  // Comment Operations

  /// Gets all comments for a shared note
  Future<List<SharedNoteComment>> getComments(String sharedNoteId) async {
    final querySnapshot = await _firestore
        .collection(commentsCollection)
        .where('sharedNoteId', isEqualTo: sharedNoteId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => SharedNoteComment.fromJson(doc.data()))
        .toList();
  }

  /// Gets a single comment by ID
  Future<SharedNoteComment?> getComment(String commentId) async {
    final docSnapshot = await _firestore
        .collection(commentsCollection)
        .doc(commentId)
        .get();

    if (!docSnapshot.exists) return null;

    return SharedNoteComment.fromJson(docSnapshot.data()!);
  }

  /// Adds a new comment
  Future<SharedNoteComment> addComment({
    required String sharedNoteId,
    required String userId,
    required String userDisplayName,
    required String content,
    String? parentCommentId,
  }) async {
    final commentId = _firestore.collection(commentsCollection).doc().id;

    final comment = SharedNoteComment(
      id: commentId,
      sharedNoteId: sharedNoteId,
      userId: userId,
      userDisplayName: userDisplayName,
      content: content,
      createdAt: DateTime.now(),
      parentCommentId: parentCommentId,
      likedBy: const [],
    );

    await _firestore
        .collection(commentsCollection)
        .doc(commentId)
        .set(comment.toJson());

    return comment;
  }

  /// Updates a comment's content
  Future<void> updateComment(String commentId, String content) async {
    await _firestore.collection(commentsCollection).doc(commentId).update({
      'content': content,
      'updatedAt': DateTime.now().toIso8601String(),
      'isEdited': true,
    });
  }

  /// Deletes a comment
  Future<void> deleteComment(String commentId) async {
    await _firestore.collection(commentsCollection).doc(commentId).delete();
  }

  /// Toggles like on a comment
  Future<void> toggleCommentLike(String commentId, String userId) async {
    final commentRef = _firestore.collection(commentsCollection).doc(commentId);

    return _firestore.runTransaction((transaction) async {
      final commentDoc = await transaction.get(commentRef);
      if (!commentDoc.exists) return;

      final comment = SharedNoteComment.fromJson(commentDoc.data()!);
      final likedBy = List<String>.from(comment.likedBy);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      transaction.update(commentRef, {'likedBy': likedBy});
    });
  }
}
