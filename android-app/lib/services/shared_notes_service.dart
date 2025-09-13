import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pensieve/models/shared_note.dart';
import 'package:pensieve/models/shared_note_comment.dart';
import 'package:pensieve/models/note_permission.dart';
import 'package:pensieve/services/family_service.dart';

/// Permission levels for note sharing
enum PermissionLevel {
  read,
  write,
  admin,
}

/// Service for managing shared notes with real-time collaboration
class SharedNotesService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FamilyService _familyService;

  SharedNotesService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FamilyService? familyService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _familyService = familyService ?? FamilyService();

  // Collection references
  CollectionReference<Map<String, dynamic>> get _sharedNotesCollection =>
      _firestore.collection('shared_notes');

  CollectionReference<Map<String, dynamic>> get _notesCollection =>
      _firestore.collection('notes');

  CollectionReference<Map<String, dynamic>> get _commentsCollection =>
      _firestore.collection('note_comments');

  CollectionReference<Map<String, dynamic>> get _collaborationCollection =>
      _firestore.collection('collaboration_sessions');

  CollectionReference<Map<String, dynamic>> get _activitiesCollection =>
      _firestore.collection('note_activities');

  /// Gets the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Shares a note with family members
  Future<ServiceResult<SharedNote>> shareNote({
    required String noteId,
    required String familyId,
    String? title,
    String? description,
    PermissionLevel permissionLevel = PermissionLevel.read,
    bool allowCollaboration = false,
    DateTime? expiresAt,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Verify user is a member of the family
      final familyMembers = await _familyService.getFamilyMembers(familyId);
      if (!familyMembers.isSuccess) {
        return ServiceResult.failure(
          error: 'Failed to verify family membership',
          code: 'FAMILY_ACCESS_FAILED',
        );
      }

      final userMember = familyMembers.data!
          .where((member) => member.userId == user.uid)
          .firstOrNull;

      if (userMember == null) {
        return ServiceResult.failure(
          error: 'User is not a member of this family',
          code: 'NOT_FAMILY_MEMBER',
        );
      }

      // Check if user has permission to share notes
      if (!userMember.permissions.canShareNotes) {
        return ServiceResult.failure(
          error: 'User does not have permission to share notes',
          code: 'PERMISSION_DENIED',
        );
      }

      // Verify note exists and user owns it
      final noteDoc = await _notesCollection.doc(noteId).get();
      if (!noteDoc.exists) {
        return ServiceResult.failure(
          error: 'Note not found',
          code: 'NOTE_NOT_FOUND',
        );
      }

      final noteData = noteDoc.data()!;
      if (noteData['userId'] != user.uid) {
        return ServiceResult.failure(
          error: 'User does not own this note',
          code: 'NOT_NOTE_OWNER',
        );
      }

      // Check if note is already shared with this family
      final existingShare = await _sharedNotesCollection
          .where('noteId', isEqualTo: noteId)
          .where('familyId', isEqualTo: familyId)
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      if (existingShare.docs.isNotEmpty) {
        return ServiceResult.failure(
          error: 'Note is already shared with this family',
          code: 'ALREADY_SHARED',
        );
      }

      // Get family settings to check if approval is required
      final familyResult = await _familyService.getFamilyById(familyId);
      if (!familyResult.isSuccess) {
        return ServiceResult.failure(
          error: 'Failed to get family settings',
          code: 'FAMILY_ACCESS_FAILED',
        );
      }

      final family = familyResult.data!;
      final requiresApproval = family.settings.requireApprovalForSharing;

      // Create appropriate permission based on level
      final permission = _createPermission(
        sharedNoteId: _sharedNotesCollection.doc().id,
        noteId: noteId,
        userId: user.uid, // This will be updated for each family member
        familyMemberId: '', // This will be updated for each family member  
        grantedBy: user.uid,
        permissionLevel: permissionLevel,
      );

      final now = DateTime.now();
      final sharedNote = SharedNote(
        id: _sharedNotesCollection.doc().id,
        noteId: noteId,
        familyId: familyId,
        sharedBy: user.uid,
        sharedAt: now,
        title: title ?? noteData['title'] ?? 'Untitled Note',
        description: description,
        permission: permission,
        requiresApproval: requiresApproval,
        status: requiresApproval ? SharingStatus.pending : SharingStatus.approved,
        allowCollaboration: allowCollaboration,
        expiresAt: expiresAt,
        updatedAt: now,
        version: 1,
      );

      // Save shared note
      await _sharedNotesCollection.doc(sharedNote.id).set(sharedNote.toJson());

      // Log activity
      await _activitiesCollection.doc().set({
        'type': 'note_shared',
        'noteId': noteId,
        'sharedNoteId': sharedNote.id,
        'familyId': familyId,
        'userId': user.uid,
        'permissionLevel': permissionLevel.toString(),
        'requiresApproval': requiresApproval,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return ServiceResult.success(data: sharedNote);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to share note: ${e.toString()}',
        code: 'SHARE_FAILED',
      );
    }
  }

  /// Gets shared notes for a family
  Future<ServiceResult<List<SharedNote>>> getFamilySharedNotes(
    String familyId, {
    bool includeExpired = false,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Verify family access
      final accessResult = await _verifyFamilyAccess(familyId);
      if (!accessResult.isSuccess) {
        return accessResult.asFailure();
      }

      var query = _sharedNotesCollection
          .where('familyId', isEqualTo: familyId)
          .where('status', isEqualTo: 'approved')
          .orderBy('sharedAt', descending: true);

      final snapshot = await query.get();
      final sharedNotes = <SharedNote>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final sharedNote = SharedNote.fromJson(data);

        // Filter expired notes if not requested
        if (!includeExpired && sharedNote.expiresAt != null) {
          if (sharedNote.expiresAt!.isBefore(DateTime.now())) {
            continue;
          }
        }

        sharedNotes.add(sharedNote);
      }

      return ServiceResult.success(data: sharedNotes);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get shared notes: ${e.toString()}',
        code: 'GET_SHARED_NOTES_FAILED',
      );
    }
  }

  /// Gets a shared note by ID with permission check
  Future<ServiceResult<SharedNoteWithContent>> getSharedNote(
    String sharedNoteId,
  ) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Get shared note
      final sharedNoteDoc = await _sharedNotesCollection.doc(sharedNoteId).get();
      if (!sharedNoteDoc.exists) {
        return ServiceResult.failure(
          error: 'Shared note not found',
          code: 'SHARED_NOTE_NOT_FOUND',
        );
      }

      final sharedNoteData = sharedNoteDoc.data()!;
      sharedNoteData['id'] = sharedNoteDoc.id;
      final sharedNote = SharedNote.fromJson(sharedNoteData);

      // Verify family access
      final accessResult = await _verifyFamilyAccess(sharedNote.familyId);
      if (!accessResult.isSuccess) {
        return accessResult.asFailure();
      }

      // Check if note has expired
      if (sharedNote.expiresAt != null &&
          sharedNote.expiresAt!.isBefore(DateTime.now())) {
        return ServiceResult.failure(
          error: 'Shared note has expired',
          code: 'NOTE_EXPIRED',
        );
      }

      // Get original note content
      final noteDoc = await _notesCollection.doc(sharedNote.noteId).get();
      if (!noteDoc.exists) {
        return ServiceResult.failure(
          error: 'Original note not found',
          code: 'NOTE_NOT_FOUND',
        );
      }

      final noteData = noteDoc.data()!;

      // Update active viewers
      await _updateActiveViewers(sharedNoteId, user.uid, add: true);

      final sharedNoteWithContent = SharedNoteWithContent(
        sharedNote: sharedNote,
        content: noteData['content'] ?? '',
        originalTitle: noteData['title'] ?? '',
        originalCreatedAt: DateTime.parse(noteData['createdAt']),
        originalUpdatedAt: DateTime.parse(noteData['updatedAt']),
      );

      return ServiceResult.success(data: sharedNoteWithContent);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get shared note: ${e.toString()}',
        code: 'GET_SHARED_NOTE_FAILED',
      );
    }
  }

  /// Updates shared note content (collaborative editing)
  Future<ServiceResult<bool>> updateSharedNoteContent({
    required String sharedNoteId,
    required String newContent,
    int? expectedVersion,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Get shared note
      final sharedNoteDoc = await _sharedNotesCollection.doc(sharedNoteId).get();
      if (!sharedNoteDoc.exists) {
        return ServiceResult.failure(
          error: 'Shared note not found',
          code: 'SHARED_NOTE_NOT_FOUND',
        );
      }

      final sharedNoteData = sharedNoteDoc.data()!;
      sharedNoteData['id'] = sharedNoteDoc.id;
      final sharedNote = SharedNote.fromJson(sharedNoteData);

      // Verify edit permission
      final editPermission = await _checkEditPermission(sharedNote.familyId, user.uid);
      if (!editPermission.isSuccess) {
        return editPermission.asFailure();
      }

      // Check sharing permission level
      if (!sharedNote.permission.canEdit) {
        return ServiceResult.failure(
          error: 'Shared note does not allow editing',
          code: 'EDIT_NOT_ALLOWED',
        );
      }

      // Version conflict check
      if (expectedVersion != null && sharedNote.version != expectedVersion) {
        return ServiceResult.failure(
          error: 'Version conflict detected',
          code: 'VERSION_CONFLICT',
        );
      }

      // Update original note content
      final batch = _firestore.batch();

      batch.update(_notesCollection.doc(sharedNote.noteId), {
        'content': newContent,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastEditedBy': user.uid,
      });

      // Update shared note version
      batch.update(_sharedNotesCollection.doc(sharedNoteId), {
        'version': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      batch.set(_activitiesCollection.doc(), {
        'type': 'note_edited',
        'noteId': sharedNote.noteId,
        'sharedNoteId': sharedNoteId,
        'familyId': sharedNote.familyId,
        'userId': user.uid,
        'contentLength': newContent.length,
        'previousVersion': sharedNote.version,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Notify other active viewers of the change
      await _notifyContentChange(sharedNoteId, user.uid, newContent);

      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to update shared note: ${e.toString()}',
        code: 'UPDATE_FAILED',
      );
    }
  }

  /// Adds a comment to a shared note
  Future<ServiceResult<SharedNoteComment>> addComment({
    required String sharedNoteId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Get shared note
      final sharedNoteDoc = await _sharedNotesCollection.doc(sharedNoteId).get();
      if (!sharedNoteDoc.exists) {
        return ServiceResult.failure(
          error: 'Shared note not found',
          code: 'SHARED_NOTE_NOT_FOUND',
        );
      }

      final sharedNoteData = sharedNoteDoc.data()!;
      final sharedNote = SharedNote.fromJson(sharedNoteData);

      // Verify comment permission
      final commentPermission = await _checkCommentPermission(sharedNote.familyId, user.uid);
      if (!commentPermission.isSuccess) {
        return commentPermission.asFailure();
      }

      // Check if commenting is allowed on this note
      if (!sharedNote.permission.canComment) {
        return ServiceResult.failure(
          error: 'Comments not allowed on this shared note',
          code: 'COMMENTS_NOT_ALLOWED',
        );
      }

      // Validate parent comment if specified
      if (parentCommentId != null) {
        final parentDoc = await _commentsCollection.doc(parentCommentId).get();
        if (!parentDoc.exists) {
          return ServiceResult.failure(
            error: 'Parent comment not found',
            code: 'PARENT_COMMENT_NOT_FOUND',
          );
        }
      }

      final now = DateTime.now();
      final comment = SharedNoteComment(
        id: _commentsCollection.doc().id,
        sharedNoteId: sharedNoteId,
        userId: user.uid,
        userDisplayName: user.displayName ?? user.email ?? 'Unknown User',
        content: content,
        parentCommentId: parentCommentId,
        createdAt: now,
        isEdited: false,
        isDeleted: false,
      );

      // Save comment
      await _commentsCollection.doc(comment.id).set(comment.toJson());

      // Log activity
      await _activitiesCollection.doc().set({
        'type': 'comment_added',
        'noteId': sharedNote.noteId,
        'sharedNoteId': sharedNoteId,
        'commentId': comment.id,
        'familyId': sharedNote.familyId,
        'userId': user.uid,
        'isReply': parentCommentId != null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return ServiceResult.success(data: comment);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to add comment: ${e.toString()}',
        code: 'ADD_COMMENT_FAILED',
      );
    }
  }

  /// Gets comments for a shared note
  Future<ServiceResult<List<SharedNoteComment>>> getComments(
    String sharedNoteId,
  ) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Get shared note to verify access
      final sharedNoteDoc = await _sharedNotesCollection.doc(sharedNoteId).get();
      if (!sharedNoteDoc.exists) {
        return ServiceResult.failure(
          error: 'Shared note not found',
          code: 'SHARED_NOTE_NOT_FOUND',
        );
      }

      final sharedNoteData = sharedNoteDoc.data()!;
      final sharedNote = SharedNote.fromJson(sharedNoteData);

      // Verify family access
      final accessResult = await _verifyFamilyAccess(sharedNote.familyId);
      if (!accessResult.isSuccess) {
        return accessResult.asFailure();
      }

      // Get comments
      final snapshot = await _commentsCollection
          .where('sharedNoteId', isEqualTo: sharedNoteId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt')
          .get();

      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SharedNoteComment.fromJson(data);
      }).toList();

      return ServiceResult.success(data: comments);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get comments: ${e.toString()}',
        code: 'GET_COMMENTS_FAILED',
      );
    }
  }

  /// Starts a real-time collaboration session
  Future<ServiceResult<String>> startCollaborationSession(
    String sharedNoteId,
  ) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Get shared note
      final sharedNoteDoc = await _sharedNotesCollection.doc(sharedNoteId).get();
      if (!sharedNoteDoc.exists) {
        return ServiceResult.failure(
          error: 'Shared note not found',
          code: 'SHARED_NOTE_NOT_FOUND',
        );
      }

      final sharedNoteData = sharedNoteDoc.data()!;
      final sharedNote = SharedNote.fromJson(sharedNoteData);

      // Check if collaboration is allowed
      if (!sharedNote.allowCollaboration) {
        return ServiceResult.failure(
          error: 'Collaboration not enabled for this note',
          code: 'COLLABORATION_DISABLED',
        );
      }

      // Verify edit permission
      final editPermission = await _checkEditPermission(sharedNote.familyId, user.uid);
      if (!editPermission.isSuccess) {
        return editPermission.asFailure();
      }

      final sessionId = _collaborationCollection.doc().id;
      final now = DateTime.now();

      // Create or update collaboration session
      await _collaborationCollection.doc(sessionId).set({
        'sharedNoteId': sharedNoteId,
        'noteId': sharedNote.noteId,
        'familyId': sharedNote.familyId,
        'createdBy': user.uid,
        'createdAt': now.toIso8601String(),
        'lastActivity': now.toIso8601String(),
        'activeUsers': [
          {
            'userId': user.uid,
            'joinedAt': now.toIso8601String(),
            'cursor': null,
            'selection': null,
          }
        ],
        'isActive': true,
      });

      // Update shared note with session ID
      await _sharedNotesCollection.doc(sharedNoteId).update({
        'collaborationSessionId': sessionId,
      });

      return ServiceResult.success(data: sessionId);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to start collaboration: ${e.toString()}',
        code: 'START_COLLABORATION_FAILED',
      );
    }
  }

  /// Gets real-time stream of shared notes for a family
  Stream<List<SharedNote>> getFamilySharedNotesStream(String familyId) {
    return _sharedNotesCollection
        .where('familyId', isEqualTo: familyId)
        .where('status', isEqualTo: 'approved')
        .orderBy('sharedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SharedNote.fromJson(data);
      }).toList();
    });
  }

  /// Gets real-time stream of comments for a shared note
  Stream<List<SharedNoteComment>> getCommentsStream(String sharedNoteId) {
    return _commentsCollection
        .where('sharedNoteId', isEqualTo: sharedNoteId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SharedNoteComment.fromJson(data);
      }).toList();
    });
  }

  /// Gets real-time stream of collaboration session
  Stream<CollaborationSession?> getCollaborationSessionStream(String sessionId) {
    return _collaborationCollection.doc(sessionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return CollaborationSession.fromJson(data);
    });
  }

  // Helper methods

  /// Verifies user has access to the family
  Future<ServiceResult<bool>> _verifyFamilyAccess(String familyId) async {
    final user = currentUser;
    if (user == null) {
      return ServiceResult.failure(
        error: 'User must be authenticated',
        code: 'AUTH_REQUIRED',
      );
    }

    final familyMembers = await _familyService.getFamilyMembers(familyId);
    if (!familyMembers.isSuccess) {
      return ServiceResult.failure(
        error: 'Failed to verify family access',
        code: 'FAMILY_ACCESS_FAILED',
      );
    }

    final userMember = familyMembers.data!
        .where((member) => member.userId == user.uid)
        .firstOrNull;

    if (userMember == null) {
      return ServiceResult.failure(
        error: 'User is not a member of this family',
        code: 'NOT_FAMILY_MEMBER',
      );
    }

    return ServiceResult.success(data: true);
  }

  /// Checks if user has edit permission
  Future<ServiceResult<bool>> _checkEditPermission(String familyId, String userId) async {
    final familyMembers = await _familyService.getFamilyMembers(familyId);
    if (!familyMembers.isSuccess) {
      return ServiceResult.failure(
        error: 'Failed to verify permissions',
        code: 'PERMISSION_CHECK_FAILED',
      );
    }

    final userMember = familyMembers.data!
        .where((member) => member.userId == userId)
        .firstOrNull;

    if (userMember == null || !userMember.permissions.canEditSharedNotes) {
      return ServiceResult.failure(
        error: 'User does not have edit permission',
        code: 'EDIT_PERMISSION_DENIED',
      );
    }

    return ServiceResult.success(data: true);
  }

  /// Checks if user has comment permission
  Future<ServiceResult<bool>> _checkCommentPermission(String familyId, String userId) async {
    final familyMembers = await _familyService.getFamilyMembers(familyId);
    if (!familyMembers.isSuccess) {
      return ServiceResult.failure(
        error: 'Failed to verify permissions',
        code: 'PERMISSION_CHECK_FAILED',
      );
    }

    final userMember = familyMembers.data!
        .where((member) => member.userId == userId)
        .firstOrNull;

    if (userMember == null || !userMember.permissions.canShareNotes) {
      return ServiceResult.failure(
        error: 'User does not have comment permission',
        code: 'COMMENT_PERMISSION_DENIED',
      );
    }

    return ServiceResult.success(data: true);
  }

  /// Updates active viewers list
  Future<void> _updateActiveViewers(String sharedNoteId, String userId, {required bool add}) async {
    try {
      if (add) {
        await _sharedNotesCollection.doc(sharedNoteId).update({
          'activeViewers': FieldValue.arrayUnion([userId]),
        });
      } else {
        await _sharedNotesCollection.doc(sharedNoteId).update({
          'activeViewers': FieldValue.arrayRemove([userId]),
        });
      }
    } catch (e) {
      // Log error but don't throw - this is a background operation
      print('Failed to update active viewers: $e');
    }
  }

  /// Creates appropriate permission based on level
  NotePermission _createPermission({
    required String sharedNoteId,
    required String noteId,
    required String userId,
    required String familyMemberId,
    required String grantedBy,
    required PermissionLevel permissionLevel,
  }) {
    switch (permissionLevel) {
      case PermissionLevel.read:
        return NotePermission.readOnly(
          id: '$sharedNoteId-$userId',
          sharedNoteId: sharedNoteId,
          userId: userId,
          familyMemberId: familyMemberId,
          grantedBy: grantedBy,
        );
      case PermissionLevel.write:
        return NotePermission.editor(
          id: '$sharedNoteId-$userId',
          sharedNoteId: sharedNoteId,
          userId: userId,
          familyMemberId: familyMemberId,
          grantedBy: grantedBy,
        );
      case PermissionLevel.admin:
        return NotePermission.fullAccess(
          id: '$sharedNoteId-$userId',
          sharedNoteId: sharedNoteId,
          userId: userId,
          familyMemberId: familyMemberId,
          grantedBy: grantedBy,
        );
    }
  }

  /// Notifies other viewers of content changes
  Future<void> _notifyContentChange(String sharedNoteId, String editorId, String newContent) async {
    try {
      // In a real implementation, this would use Cloud Functions or FCM
      // to send real-time notifications to active viewers
      print('Content changed in $sharedNoteId by $editorId');
    } catch (e) {
      print('Failed to notify content change: $e');
    }
  }
}

/// Extended shared note with content
class SharedNoteWithContent {
  final SharedNote sharedNote;
  final String content;
  final String originalTitle;
  final DateTime originalCreatedAt;
  final DateTime originalUpdatedAt;

  const SharedNoteWithContent({
    required this.sharedNote,
    required this.content,
    required this.originalTitle,
    required this.originalCreatedAt,
    required this.originalUpdatedAt,
  });
}

/// Collaboration session model
class CollaborationSession {
  final String id;
  final String sharedNoteId;
  final String noteId;
  final String familyId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime lastActivity;
  final List<ActiveUser> activeUsers;
  final bool isActive;

  const CollaborationSession({
    required this.id,
    required this.sharedNoteId,
    required this.noteId,
    required this.familyId,
    required this.createdBy,
    required this.createdAt,
    required this.lastActivity,
    required this.activeUsers,
    required this.isActive,
  });

  factory CollaborationSession.fromJson(Map<String, dynamic> json) {
    return CollaborationSession(
      id: json['id'],
      sharedNoteId: json['sharedNoteId'],
      noteId: json['noteId'],
      familyId: json['familyId'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      lastActivity: DateTime.parse(json['lastActivity']),
      activeUsers: (json['activeUsers'] as List)
          .map((user) => ActiveUser.fromJson(user))
          .toList(),
      isActive: json['isActive'] ?? true,
    );
  }
}

/// Active user in collaboration session
class ActiveUser {
  final String userId;
  final DateTime joinedAt;
  final Map<String, dynamic>? cursor;
  final Map<String, dynamic>? selection;

  const ActiveUser({
    required this.userId,
    required this.joinedAt,
    this.cursor,
    this.selection,
  });

  factory ActiveUser.fromJson(Map<String, dynamic> json) {
    return ActiveUser(
      userId: json['userId'],
      joinedAt: DateTime.parse(json['joinedAt']),
      cursor: json['cursor'],
      selection: json['selection'],
    );
  }
}