/// Permission Service
///
/// Core business logic for permission management within families.
/// Handles permission validation, role-based access control, and permission inheritance.
/// Integrates with Firebase Auth and Firestore for secure permission enforcement.
///
/// This service acts as the central authority for all permission-related operations,
/// ensuring consistent and secure access control across the family management system.

import '../../../models/family_member.dart';
import '../../../models/shared_note.dart';
import '../../../models/note_permission.dart';
import '../repositories/family_repository.dart';
import '../repositories/shared_notes_repository.dart';
import '../providers/auth_providers.dart';

class PermissionService {
  final FamilyRepository _familyRepository;
  final SharedNotesRepository _sharedNotesRepository;
  final AuthGuard _authGuard;

  PermissionService(this._familyRepository, this._sharedNotesRepository, this._authGuard);

  /// Checks if a user can perform a specific action on a family
  Future<bool> canPerformFamilyAction(
    String familyId,
    String userId,
    FamilyAction action,
  ) async {
    final member = await _familyRepository.getFamilyMember(familyId, userId);
    if (member == null) return false;

    switch (action) {
      case FamilyAction.inviteMembers:
        return member.permissions.canInviteMembers;
      case FamilyAction.removeMembers:
        return member.permissions.canRemoveMembers;
      case FamilyAction.shareNotes:
        return member.permissions.canShareNotes;
      case FamilyAction.editSharedNotes:
        return member.permissions.canEditSharedNotes;
      case FamilyAction.deleteSharedNotes:
        return member.permissions.canDeleteSharedNotes;
      case FamilyAction.managePermissions:
        return member.permissions.canManagePermissions;
      case FamilyAction.manageFamily:
        return member.role == FamilyRole.owner || member.role == FamilyRole.admin;
      case FamilyAction.deleteFamily:
        return member.role == FamilyRole.owner;
    }
  }

  /// Checks if a user can perform a specific action on a shared note
  Future<bool> canPerformSharedNoteAction(
    String sharedNoteId,
    String userId,
    SharedNoteAction action,
  ) async {
    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) return false;

    // Sharer always has full permissions
    if (sharedNote.sharedBy == userId) return true;

    // Check if user is family member
    final member = await _familyRepository.getFamilyMember(sharedNote.familyId, userId);
    if (member == null) return false;

    // Check if sharing is active
    if (!sharedNote.status.isActive) return false;

    // Check if sharing has expired
    if (sharedNote.expiresAt != null && sharedNote.expiresAt!.isBefore(DateTime.now())) {
      return false;
    }

    // Get user's specific permissions for this note
    final permission = await _sharedNotesRepository.getPermissionForUser(sharedNoteId, userId);
    if (permission == null || !permission.isActive) return false;

    switch (action) {
      case SharedNoteAction.view:
        return permission.canView;
      case SharedNoteAction.edit:
        return permission.canEdit;
      case SharedNoteAction.comment:
        return permission.canComment;
      case SharedNoteAction.delete:
        return permission.canDelete;
      case SharedNoteAction.share:
        return permission.canShare;
      case SharedNoteAction.export:
        return permission.canExport;
      case SharedNoteAction.inviteCollaborators:
        return permission.canInviteCollaborators;
    }
  }

  /// Validates and enforces permissions for a family operation
  Future<void> enforceFamilyPermission(
    String familyId,
    FamilyAction action, {
    String? errorMessage,
  }) async {
    _authGuard.requireAuthentication();
    final userId = _authGuard.user!.uid;

    final hasPermission = await canPerformFamilyAction(familyId, userId, action);
    if (!hasPermission) {
      throw Exception(errorMessage ?? 'Insufficient permissions for action: ${action.name}');
    }
  }

  /// Validates and enforces permissions for a shared note operation
  Future<void> enforceSharedNotePermission(
    String sharedNoteId,
    SharedNoteAction action, {
    String? errorMessage,
  }) async {
    _authGuard.requireAuthentication();
    final userId = _authGuard.user!.uid;

    final hasPermission = await canPerformSharedNoteAction(sharedNoteId, userId, action);
    if (!hasPermission) {
      throw Exception(errorMessage ?? 'Insufficient permissions for action: ${action.name}');
    }
  }

  /// Gets all permissions for a user across all shared notes in their family
  Future<List<NotePermission>> getUserPermissionsInFamily(String familyId, String userId) async {
    final sharedNotes = await _sharedNotesRepository.getSharedNotesForFamily(familyId);
    final permissions = <NotePermission>[];

    for (final note in sharedNotes) {
      final permission = await _sharedNotesRepository.getPermissionForUser(note.id, userId);
      if (permission != null) {
        permissions.add(permission);
      }
    }

    return permissions;
  }

  /// Gets effective permissions for a user on a specific shared note
  Future<EffectivePermissions> getEffectivePermissions(
    String sharedNoteId,
    String userId,
  ) async {
    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      return EffectivePermissions.empty();
    }

    // Sharer has all permissions
    if (sharedNote.sharedBy == userId) {
      return EffectivePermissions.all();
    }

    // Get family membership
    final member = await _familyRepository.getFamilyMember(sharedNote.familyId, userId);
    if (member == null) {
      return EffectivePermissions.empty();
    }

    // Get specific note permissions
    final permission = await _sharedNotesRepository.getPermissionForUser(sharedNoteId, userId);
    if (permission == null || !permission.isActive) {
      return EffectivePermissions.empty();
    }

    // Check if sharing is active and not expired
    final isActive = sharedNote.status.isActive &&
                    (sharedNote.expiresAt == null || sharedNote.expiresAt!.isAfter(DateTime.now()));

    if (!isActive) {
      return EffectivePermissions.empty();
    }

    return EffectivePermissions(
      canView: permission.canView,
      canEdit: permission.canEdit,
      canComment: permission.canComment,
      canDelete: permission.canDelete,
      canShare: permission.canShare,
      canExport: permission.canExport,
      canInviteCollaborators: permission.canInviteCollaborators,
      receiveNotifications: permission.receiveNotifications,
      isActive: isActive,
      role: member.role,
      familyPermissions: member.permissions,
    );
  }

  /// Updates permissions for multiple users on a shared note
  Future<void> bulkUpdatePermissions(
    String sharedNoteId,
    Map<String, NotePermission> userPermissions,
  ) async {
    _authGuard.requireAuthentication();

    final sharedNote = await _sharedNotesRepository.getSharedNote(sharedNoteId);
    if (sharedNote == null) {
      throw Exception('Shared note not found');
    }

    // Check if user can manage permissions
    await enforceFamilyPermission(
      sharedNote.familyId,
      FamilyAction.managePermissions,
      errorMessage: 'Cannot manage permissions for this shared note',
    );

    for (final entry in userPermissions.entries) {
      await _sharedNotesRepository.updateMemberPermissions(
        sharedNoteId,
        entry.key,
        entry.value,
      );
    }
  }

  /// Revokes all permissions for a user on all shared notes in a family
  Future<void> revokeAllUserPermissions(String familyId, String userId) async {
    _authGuard.requireAuthentication();

    // Check if current user can manage permissions
    await enforceFamilyPermission(
      familyId,
      FamilyAction.managePermissions,
      errorMessage: 'Cannot revoke user permissions',
    );

    final sharedNotes = await _sharedNotesRepository.getSharedNotesForFamily(familyId);

    for (final note in sharedNotes) {
      await _sharedNotesRepository.deactivatePermission(note.id, userId);
    }
  }

  /// Validates permission consistency across a family
  Future<List<PermissionValidationError>> validateFamilyPermissions(String familyId) async {
    final errors = <PermissionValidationError>[];

    final members = await _familyRepository.getFamilyMembers(familyId);
    final sharedNotes = await _sharedNotesRepository.getSharedNotesForFamily(familyId);

    for (final note in sharedNotes) {
      for (final member in members) {
        // Skip sharer - they have implicit permissions
        if (member.userId == note.sharedBy) continue;

        final permission = await _sharedNotesRepository.getPermissionForUser(note.id, member.userId);

        // Check for missing permissions
        if (permission == null) {
          errors.add(PermissionValidationError(
            type: PermissionValidationErrorType.missingPermission,
            sharedNoteId: note.id,
            userId: member.userId,
            message: 'User ${member.userId} has no permissions for shared note ${note.id}',
          ));
          continue;
        }

        // Check for expired permissions
        if (permission.expiresAt != null && permission.expiresAt!.isBefore(DateTime.now())) {
          errors.add(PermissionValidationError(
            type: PermissionValidationErrorType.expiredPermission,
            sharedNoteId: note.id,
            userId: member.userId,
            message: 'Permission expired for user ${member.userId} on shared note ${note.id}',
          ));
        }

        // Check permission consistency with role
        if (member.role == FamilyRole.viewer && (permission.canEdit || permission.canDelete)) {
          errors.add(PermissionValidationError(
            type: PermissionValidationErrorType.inconsistentPermission,
            sharedNoteId: note.id,
            userId: member.userId,
            message: 'Viewer role has edit/delete permissions on shared note ${note.id}',
          ));
        }
      }
    }

    return errors;
  }

  /// Repairs permission inconsistencies in a family
  Future<void> repairFamilyPermissions(String familyId) async {
    _authGuard.requireAuthentication();

    // Only family owner/admin can repair permissions
    await enforceFamilyPermission(
      familyId,
      FamilyAction.manageFamily,
      errorMessage: 'Cannot repair family permissions',
    );

    final errors = await validateFamilyPermissions(familyId);

    for (final error in errors) {
      switch (error.type) {
        case PermissionValidationErrorType.missingPermission:
          // Create default permissions for missing entries
          final sharedNote = await _sharedNotesRepository.getSharedNote(error.sharedNoteId!);
          final member = await _familyRepository.getFamilyMember(familyId, error.userId!);
          if (sharedNote != null && member != null) {
            final defaultPermission = NotePermission(
              id: '',
              sharedNoteId: error.sharedNoteId!,
              userId: error.userId!,
              familyMemberId: '${familyId}_${error.userId!}',
              canView: true,
              canEdit: member.permissions.canEditSharedNotes,
              canComment: member.permissions.canEditSharedNotes,
              canDelete: false,
              canShare: member.permissions.canShareNotes,
              canExport: member.permissions.canShareNotes,
              canInviteCollaborators: member.permissions.canInviteMembers,
              receiveNotifications: true,
              grantedAt: DateTime.now(),
              grantedBy: _authGuard.user!.uid,
            );
            await _sharedNotesRepository.createPermission(defaultPermission);
          }
          break;

        case PermissionValidationErrorType.expiredPermission:
          // Deactivate expired permissions
          await _sharedNotesRepository.deactivatePermission(error.sharedNoteId!, error.userId!);
          break;

        case PermissionValidationErrorType.inconsistentPermission:
          // Fix inconsistent permissions based on role
          final member = await _familyRepository.getFamilyMember(familyId, error.userId!);
          if (member != null) {
            final correctedPermission = await _sharedNotesRepository.getPermissionForUser(
              error.sharedNoteId!,
              error.userId!,
            );
            if (correctedPermission != null) {
              final fixedPermission = correctedPermission.copyWith(
                canEdit: member.role != FamilyRole.viewer && member.permissions.canEditSharedNotes,
                canDelete: false, // Never allow delete for non-owners
              );
              await _sharedNotesRepository.updateMemberPermissions(
                error.sharedNoteId!,
                error.userId!,
                fixedPermission,
              );
            }
          }
          break;
      }
    }
  }
}

/// Enumeration of family-level actions that require permissions
enum FamilyAction {
  inviteMembers,
  removeMembers,
  shareNotes,
  editSharedNotes,
  deleteSharedNotes,
  managePermissions,
  manageFamily,
  deleteFamily,
}

/// Enumeration of shared note actions that require permissions
enum SharedNoteAction {
  view,
  edit,
  comment,
  delete,
  share,
  export,
  inviteCollaborators,
}

/// Extension methods for actions
extension FamilyActionExtension on FamilyAction {
  String get displayName {
    switch (this) {
      case FamilyAction.inviteMembers:
        return 'Invite Members';
      case FamilyAction.removeMembers:
        return 'Remove Members';
      case FamilyAction.shareNotes:
        return 'Share Notes';
      case FamilyAction.editSharedNotes:
        return 'Edit Shared Notes';
      case FamilyAction.deleteSharedNotes:
        return 'Delete Shared Notes';
      case FamilyAction.managePermissions:
        return 'Manage Permissions';
      case FamilyAction.manageFamily:
        return 'Manage Family';
      case FamilyAction.deleteFamily:
        return 'Delete Family';
    }
  }
}

extension SharedNoteActionExtension on SharedNoteAction {
  String get displayName {
    switch (this) {
      case SharedNoteAction.view:
        return 'View';
      case SharedNoteAction.edit:
        return 'Edit';
      case SharedNoteAction.comment:
        return 'Comment';
      case SharedNoteAction.delete:
        return 'Delete';
      case SharedNoteAction.share:
        return 'Share';
      case SharedNoteAction.export:
        return 'Export';
      case SharedNoteAction.inviteCollaborators:
        return 'Invite Collaborators';
    }
  }
}

/// Represents the effective permissions for a user on a shared note
class EffectivePermissions {
  final bool canView;
  final bool canEdit;
  final bool canComment;
  final bool canDelete;
  final bool canShare;
  final bool canExport;
  final bool canInviteCollaborators;
  final bool receiveNotifications;
  final bool isActive;
  final FamilyRole? role;
  final MemberPermissions? familyPermissions;

  EffectivePermissions({
    required this.canView,
    required this.canEdit,
    required this.canComment,
    required this.canDelete,
    required this.canShare,
    required this.canExport,
    required this.canInviteCollaborators,
    required this.receiveNotifications,
    required this.isActive,
    this.role,
    this.familyPermissions,
  });

  factory EffectivePermissions.empty() => EffectivePermissions(
    canView: false,
    canEdit: false,
    canComment: false,
    canDelete: false,
    canShare: false,
    canExport: false,
    canInviteCollaborators: false,
    receiveNotifications: false,
    isActive: false,
  );

  factory EffectivePermissions.all() => EffectivePermissions(
    canView: true,
    canEdit: true,
    canComment: true,
    canDelete: true,
    canShare: true,
    canExport: true,
    canInviteCollaborators: true,
    receiveNotifications: true,
    isActive: true,
  );

  bool get hasAnyPermissions => canView || canEdit || canComment || canDelete ||
                               canShare || canExport || canInviteCollaborators;
}

/// Represents a permission validation error
class PermissionValidationError {
  final PermissionValidationErrorType type;
  final String? sharedNoteId;
  final String? userId;
  final String message;

  PermissionValidationError({
    required this.type,
    this.sharedNoteId,
    this.userId,
    required this.message,
  });
}

/// Types of permission validation errors
enum PermissionValidationErrorType {
  missingPermission,
  expiredPermission,
  inconsistentPermission,
}
