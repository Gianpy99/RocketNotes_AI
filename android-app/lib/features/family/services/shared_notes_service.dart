import '../../../models/shared_note.dart';
import '../../../models/shared_note_comment.dart';
import '../../../models/note_permission.dart';
import '../../../models/family_member.dart';
import '../repositories/shared_notes_repository.dart';
import '../repositories/family_repository.dart';
import '../providers/auth_providers.dart';

class SharedNotesService {
  final SharedNotesRepository _sharedNotesRepository;
  final FamilyRepository _familyRepository;
  final AuthGuard _authGuard;

  SharedNotesService(this._sharedNotesRepository, this._familyRepository, this._authGuard);

  /// Shares a note with the user's family
  Future<SharedNote> shareNote({
    required String noteId,
    required String title,
    required NotePermission permission,
    String? description,
    bool requiresApproval = false,
    DateTime? expiresAt,
    bool allowCollaboration = false,
  }) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    // Get user's family
    final familyId = _authGuard.familyId;
    if (familyId == null) {
      throw Exception('User must be part of a family to share notes');
    }

    // Check if user has permission to share notes
    if (!await _canShareNotes(familyId, currentUser.uid)) {
      throw Exception('User does not have permission to share notes');
    }

    // Check if note is already shared
    final existingShare = await _sharedNotesRepository.getSharedNoteByNoteId(noteId, familyId);
    if (existingShare != null) {
      throw Exception('Note is already shared with this family');
    }

    // Create shared note
    final sharedNote = await _sharedNotesRepository.createSharedNote(
      noteId: noteId,
      familyId: familyId,
      sharedBy: currentUser.uid,
      title: title,
      permission: permission,
      description: description,
      requiresApproval: requiresApproval,
      expiresAt: expiresAt,
      allowCollaboration: allowCollaboration,
    );

    // If approval is not required, auto-approve
    if (!requiresApproval) {
      await _approveSharedNote(sharedNote.id, currentUser.uid);
    }

    return sharedNote;
  }

  /// Gets all shared notes for the current user's family
  Future<List<SharedNote>> getSharedNotes() async {
    _authGuard.requireAuthentication();
    final familyId = _authGuard.familyId;
    if (familyId == null) return [];

    return _sharedNotesRepository.getSharedNotesForFamily(familyId);
  }

  /// Gets a specific shared note with access validation
  Future<SharedNote?> getSharedNote(String sharedNoteId) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) return null;

    // Check if user has access to this shared note
    if (!await _canAccessSharedNote(sharedNote, currentUser.uid)) {
      throw Exception('User does not have access to this shared note');
    }

    return sharedNote;
  }

  /// Updates a shared note (owner only)
  Future<void> updateSharedNote(
    String sharedNoteId, {
    String? title,
    String? description,
    NotePermission? permission,
    DateTime? expiresAt,
    bool? allowCollaboration,
  }) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    // Only the sharer can update the note
    if (sharedNote.sharedBy != currentUser.uid) {
      throw Exception('Only the note sharer can update sharing settings');
    }

    await _sharedNotesRepository.updateSharedNote(
      sharedNoteId,
      title: title,
      description: description,
      permission: permission,
      expiresAt: expiresAt,
      allowCollaboration: allowCollaboration,
    );
  }

  /// Approves a shared note (family admin/owner only)
  Future<void> approveSharedNote(String sharedNoteId) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    // Check if user can approve notes
    if (!await _canApproveSharedNotes(sharedNote.familyId, currentUser.uid)) {
      throw Exception('User does not have permission to approve shared notes');
    }

    await _approveSharedNote(sharedNoteId, currentUser.uid);
  }

  /// Rejects a shared note (family admin/owner only)
  Future<void> rejectSharedNote(String sharedNoteId, {String? reason}) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    // Check if user can approve notes
    if (!await _canApproveSharedNotes(sharedNote.familyId, currentUser.uid)) {
      throw Exception('User does not have permission to reject shared notes');
    }

    await _sharedNotesRepository.updateSharedNoteStatus(
      sharedNoteId,
      SharingStatus.rejected,
      approvedBy: currentUser.uid,
    );

    // TODO: Send notification to sharer about rejection
  }

  /// Revokes sharing of a note (sharer or admin only)
  Future<void> revokeSharedNote(String sharedNoteId) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    // Check if user can revoke this share
    final canRevoke = sharedNote.sharedBy == currentUser.uid ||
                      await _canApproveSharedNotes(sharedNote.familyId, currentUser.uid);

    if (!canRevoke) {
      throw Exception('User does not have permission to revoke this shared note');
    }

    await _sharedNotesRepository.updateSharedNoteStatus(
      sharedNoteId,
      SharingStatus.revoked,
      approvedBy: currentUser.uid,
    );

    // Clean up permissions
    await _sharedNotesRepository.removeAllPermissionsForSharedNote(sharedNoteId);
  }

  /// Gets permissions for a shared note
  Future<List<NotePermission>> getSharedNotePermissions(String sharedNoteId) async {
    _authGuard.requireAuthentication();

    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) return [];

    // Check if user has access to view permissions
    if (!await _canManagePermissions(sharedNote.familyId, _authGuard.user!.uid)) {
      throw Exception('User does not have permission to view permissions');
    }

    return _sharedNotesRepository.getPermissionsForSharedNote(sharedNoteId);
  }

  /// Updates permissions for a family member on a shared note
  Future<void> updateMemberPermissions(
    String sharedNoteId,
    String memberUserId,
    NotePermission newPermissions,
  ) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    // Check if user can manage permissions
    if (!await _canManagePermissions(sharedNote.familyId, currentUser.uid)) {
      throw Exception('User does not have permission to manage permissions');
    }

    // Check if target user is a family member
    final member = await _familyRepository.getFamilyMember(sharedNote.familyId, memberUserId);
    if (member == null) {
      throw Exception('User is not a member of this family');
    }

    await _sharedNotesRepository.updateMemberPermissions(
      sharedNoteId,
      memberUserId,
      newPermissions,
    );
  }

  /// Starts a collaboration session for a shared note
  Future<String> startCollaborationSession(String sharedNoteId) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    // Check if collaboration is allowed
    if (!sharedNote.allowCollaboration) {
      throw Exception('Collaboration is not enabled for this shared note');
    }

    // Check if user has edit permissions
    if (!await _canEditSharedNote(sharedNote, currentUser.uid)) {
      throw Exception('User does not have permission to collaborate on this note');
    }

    // Check if session already exists
    if (sharedNote.collaborationSessionId != null) {
      return sharedNote.collaborationSessionId!;
    }

    final sessionId = await _sharedNotesRepository.createCollaborationSession(sharedNoteId);
    return sessionId;
  }

  /// Ends a collaboration session
  Future<void> endCollaborationSession(String sharedNoteId) async {
    _authGuard.requireAuthentication();

    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    // Only the sharer can end collaboration sessions
    if (sharedNote.sharedBy != _authGuard.user!.uid) {
      throw Exception('Only the note sharer can end collaboration sessions');
    }

    await _sharedNotesRepository.endCollaborationSession(sharedNoteId);
  }

  /// Updates active viewers for a shared note
  Future<void> updateActiveViewers(String sharedNoteId, List<String> viewerUserIds) async {
    _authGuard.requireAuthentication();

    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) return;

    // Only update if user has access to the note
    if (await _canAccessSharedNote(sharedNote, _authGuard.user!.uid)) {
      await _sharedNotesRepository.updateActiveViewers(sharedNoteId, viewerUserIds);
    }
  }

  /// Gets shared notes that require approval
  Future<List<SharedNote>> getPendingApprovals() async {
    _authGuard.requireAuthentication();
    final familyId = _authGuard.familyId;
    if (familyId == null) return [];

    // Check if user can approve notes
    if (!await _canApproveSharedNotes(familyId, _authGuard.user!.uid)) {
      return [];
    }

    return _sharedNotesRepository.getSharedNotesByStatus(familyId, SharingStatus.pending);
  }

  /// Gets shared notes created by the current user
  Future<List<SharedNote>> getMySharedNotes() async {
    _authGuard.requireAuthentication();
    return _sharedNotesRepository.getSharedNotesByUser(_authGuard.user!.uid);
  }

  // Private helper methods

  Future<void> _approveSharedNote(String sharedNoteId, String approvedBy) async {
    await _sharedNotesRepository.updateSharedNoteStatus(
      sharedNoteId,
      SharingStatus.approved,
      approvedBy: approvedBy,
    );

    // Create default permissions for all family members
    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote != null) {
      await _createDefaultPermissionsForSharedNote(sharedNote);
    }
  }

  Future<void> _createDefaultPermissionsForSharedNote(SharedNote sharedNote) async {
    final familyMembers = await _familyRepository.getFamilyMembers(sharedNote.familyId);

    for (final member in familyMembers) {
      // Skip the sharer - they get full permissions
      if (member.userId == sharedNote.sharedBy) continue;

      final permission = NotePermission(
        id: '', // Will be generated by repository
        sharedNoteId: sharedNote.id,
        userId: member.userId,
        familyMemberId: '${sharedNote.familyId}_${member.userId}', // Composite key
        canView: true, // Everyone can view by default
        canEdit: sharedNote.permission.canEdit && member.permissions.canEditSharedNotes,
        canComment: sharedNote.permission.canComment && member.permissions.canEditSharedNotes, // Using canEditSharedNotes as proxy
        canDelete: false, // Only sharer can delete
        canShare: sharedNote.permission.canShare && member.permissions.canShareNotes,
        canExport: sharedNote.permission.canExport && member.permissions.canShareNotes, // Using canShareNotes as proxy
        canInviteCollaborators: sharedNote.permission.canInviteCollaborators && member.permissions.canInviteMembers, // Using canInviteMembers as proxy
        receiveNotifications: true, // Everyone gets notifications by default
        grantedAt: DateTime.now(),
        grantedBy: sharedNote.sharedBy,
      );

      await _sharedNotesRepository.createPermission(permission);
    }
  }

  Future<bool> _canShareNotes(String familyId, String userId) async {
    final member = await _familyRepository.getFamilyMember(familyId, userId);
    return member?.permissions.canShareNotes ?? false;
  }

  Future<bool> _canApproveSharedNotes(String familyId, String userId) async {
    final member = await _familyRepository.getFamilyMember(familyId, userId);
    return member?.role == FamilyRole.owner || member?.role == FamilyRole.admin;
  }

  Future<bool> _canManagePermissions(String familyId, String userId) async {
    final member = await _familyRepository.getFamilyMember(familyId, userId);
    return member?.permissions.canManagePermissions ?? false;
  }

  Future<bool> _canAccessSharedNote(SharedNote sharedNote, String userId) async {
    // Sharer always has access
    if (sharedNote.sharedBy == userId) return true;

    // Check if user is family member
    final member = await _familyRepository.getFamilyMember(sharedNote.familyId, userId);
    if (member == null) return false;

    // Check if sharing is approved
    if (!sharedNote.status.isActive) return false;

    // Check if sharing has expired
    if (sharedNote.expiresAt != null && sharedNote.expiresAt!.isBefore(DateTime.now())) {
      return false;
    }

    return true;
  }

  Future<bool> _canEditSharedNote(SharedNote sharedNote, String userId) async {
    if (!await _canAccessSharedNote(sharedNote, userId)) return false;

    final permission = await _sharedNotesRepository.getPermissionForUser(sharedNote.id, userId);
    return permission?.canEdit ?? false;
  }

  /// Gets all comments for a shared note
  Future<List<SharedNoteComment>> getComments(String sharedNoteId) async {
    _authGuard.requireAuthentication();

    // Verify user has access to the shared note
    final sharedNote = await getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    if (!await _canAccessSharedNote(sharedNote, _authGuard.user!.uid)) {
      throw Exception('User does not have permission to view comments');
    }

    return await _sharedNotesRepository.getComments(sharedNoteId);
  }

  /// Adds a comment to a shared note
  Future<SharedNoteComment> addComment({
    required String sharedNoteId,
    required String content,
    String? parentCommentId,
  }) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    // Verify user has access to the shared note
    final sharedNote = await getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    if (!await _canAccessSharedNote(sharedNote, currentUser.uid)) {
      throw Exception('User does not have permission to comment');
    }

    // Get user display name from Firebase Auth
    final displayName = currentUser.displayName ?? 'Unknown User';

    return await _sharedNotesRepository.addComment(
      sharedNoteId: sharedNoteId,
      userId: currentUser.uid,
      userDisplayName: displayName,
      content: content,
      parentCommentId: parentCommentId,
    );
  }

  /// Updates a comment
  Future<void> updateComment({
    required String sharedNoteId,
    required String commentId,
    required String content,
  }) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    // Verify user has access to the shared note
    final sharedNote = await getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    if (!await _canAccessSharedNote(sharedNote, currentUser.uid)) {
      throw Exception('User does not have permission to edit comments');
    }

    // Verify user owns the comment
    final comment = await _sharedNotesRepository.getComment(commentId);
    if (comment == null) {
      throw Exception('Comment not found');
    }

    if (comment.userId != currentUser.uid) {
      throw Exception('User can only edit their own comments');
    }

    await _sharedNotesRepository.updateComment(commentId, content);
  }

  /// Deletes a comment
  Future<void> deleteComment({
    required String sharedNoteId,
    required String commentId,
  }) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    // Verify user has access to the shared note
    final sharedNote = await getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    if (!await _canAccessSharedNote(sharedNote, currentUser.uid)) {
      throw Exception('User does not have permission to delete comments');
    }

    // Verify user owns the comment
    final comment = await _sharedNotesRepository.getComment(commentId);
    if (comment == null) {
      throw Exception('Comment not found');
    }

    if (comment.userId != currentUser.uid) {
      throw Exception('User can only delete their own comments');
    }

    await _sharedNotesRepository.deleteComment(commentId);
  }

  /// Toggles like on a comment
  Future<void> toggleCommentLike({
    required String sharedNoteId,
    required String commentId,
  }) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    // Verify user has access to the shared note
    final sharedNote = await getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    if (!await _canAccessSharedNote(sharedNote, currentUser.uid)) {
      throw Exception('User does not have permission to like comments');
    }

    await _sharedNotesRepository.toggleCommentLike(commentId, currentUser.uid);
  }
}
