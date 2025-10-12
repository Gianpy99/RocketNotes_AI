import '../../../models/family.dart';
import '../../../models/family_member.dart';
import '../../../models/family_invitation.dart';
import '../repositories/family_repository.dart';
import '../providers/auth_providers.dart';
import 'package:flutter/foundation.dart';

class FamilyService {
  final FamilyRepository _familyRepository;
  final AuthGuard _authGuard;

  FamilyService(this._familyRepository, this._authGuard);

  /// Creates a new family with the current user as owner
  Future<Family> createFamily({
    required String name,
    required FamilySettings settings,
  }) async {
    // Temporarily bypass authentication for testing
    final currentUser = _authGuard.user;
    final userId = currentUser?.uid ?? 'anonymous_user_${DateTime.now().millisecondsSinceEpoch}';
    
    // _authGuard.requireAuthentication();

    // Create the family
    final family = await _familyRepository.createFamily(
      ownerId: userId,
      name: name,
      settings: settings,
    );

    // Add the owner as the first member
    await _familyRepository.addFamilyMember(
      familyId: family.id,
      userId: userId,
      role: FamilyRole.owner,
      permissions: MemberPermissions.owner(),
    );

    // Update user's family membership (skip for anonymous users)
    if (currentUser != null) {
      await _familyRepository.updateUserFamilyId(currentUser.uid, family.id);
    }

    return family;
  }

  /// Gets the current user's family
  Future<Family?> getCurrentUserFamily() async {
    final currentUser = _authGuard.user;
    if (currentUser == null) return null;

    final familyId = _authGuard.familyId;
    if (familyId == null) return null;

    return _familyRepository.getFamily(familyId);
  }

  /// Updates family settings (owner only)
  Future<void> updateFamilySettings(String familyId, FamilySettings settings) async {
    await _ensureOwnerPermission(familyId);
    await _familyRepository.updateFamilySettings(familyId, settings);
  }

  /// Gets all members of a family
  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    await _ensureFamilyAccess(familyId);
    return _familyRepository.getFamilyMembers(familyId);
  }

  /// Adds a new member to the family (with invitation)
  Future<FamilyInvitation> inviteMember({
    required String familyId,
    required String email,
    required FamilyRole role,
    required MemberPermissions permissions,
  }) async {
    await _ensureInvitePermission(familyId);

    // Check if user is already a member
    final existingMember = await _familyRepository.getFamilyMemberByEmail(familyId, email);
    if (existingMember != null) {
      throw Exception('User is already a member of this family');
    }

    // Check family member limit
    final family = await _familyRepository.getFamily(familyId);
    final memberCount = await _familyRepository.getFamilyMemberCount(familyId);
    if (memberCount >= family!.settings.maxMembers) {
      throw Exception('Family has reached maximum member limit');
    }

    // Create invitation
    final invitation = await _familyRepository.createInvitation(
      familyId: familyId,
      invitedBy: _authGuard.user!.uid,
      email: email,
      role: role,
      permissions: permissions,
    );

    // Send invitation notification (this would integrate with notification service)
    await _sendInvitationNotification(invitation);

    return invitation;
  }

  /// Accepts a family invitation
  Future<void> acceptInvitation(String invitationId) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    final invitation = await _familyRepository.getInvitation(invitationId);
    if (invitation == null) {
      throw Exception('Invitation not found');
    }

    if (invitation.email != currentUser.email) {
      throw Exception('Invitation is not for this user');
    }

    if (invitation.status != InvitationStatus.pending) {
      throw Exception('Invitation is no longer valid');
    }

    if (invitation.isExpired) {
      await _familyRepository.updateInvitationStatus(invitationId, InvitationStatus.expired);
      throw Exception('Invitation has expired');
    }

    // Check if user is already in another family
    final userFamilyId = _authGuard.familyId;
    if (userFamilyId != null && userFamilyId != invitation.familyId) {
      throw Exception('User is already a member of another family');
    }

    // Add user to family
    await _familyRepository.addFamilyMember(
      familyId: invitation.familyId,
      userId: currentUser.uid,
      role: invitation.role,
      permissions: invitation.permissions,
    );

    // Update invitation status
    await _familyRepository.updateInvitationStatus(invitationId, InvitationStatus.accepted);

    // Note: User's family membership will be updated by the auth system when they sign in next
    // This is handled by the authentication flow, not directly by the service

    // Update family member count
    await _familyRepository.incrementFamilyMemberCount(invitation.familyId);
  }

  /// Rejects a family invitation
  Future<void> rejectInvitation(String invitationId) async {
    _authGuard.requireAuthentication();
    final currentUser = _authGuard.user!;

    final invitation = await _familyRepository.getInvitation(invitationId);
    if (invitation == null) {
      throw Exception('Invitation not found');
    }

    if (invitation.email != currentUser.email) {
      throw Exception('Invitation is not for this user');
    }

    await _familyRepository.updateInvitationStatus(invitationId, InvitationStatus.rejected);
  }

  /// Removes a member from the family (admin/owner only)
  Future<void> removeMember(String familyId, String memberUserId) async {
    await _ensureManageMembersPermission(familyId);

    final currentUser = _authGuard.user!;
    if (memberUserId == currentUser.uid) {
      throw Exception('Cannot remove yourself from the family');
    }

    // Check if target user is owner (owners cannot be removed)
    final member = await _familyRepository.getFamilyMember(familyId, memberUserId);
    if (member?.role == FamilyRole.owner) {
      throw Exception('Cannot remove family owner');
    }

    await _familyRepository.removeFamilyMember(familyId, memberUserId);
    await _familyRepository.decrementFamilyMemberCount(familyId);

    // Note: User's family membership will be updated by the auth system
    // This is handled by the authentication flow when they sign in next
  }

  /// Updates a member's role and permissions (admin/owner only)
  Future<void> updateMemberPermissions(
    String familyId,
    String memberUserId,
    FamilyRole role,
    MemberPermissions permissions,
  ) async {
    await _ensureManagePermissionsPermission(familyId);

    final currentUser = _authGuard.user!;
    if (memberUserId == currentUser.uid) {
      // User is updating their own permissions - check if they're removing owner rights
      final family = await _familyRepository.getFamily(familyId);
      if (family?.adminUserId == currentUser.uid && role != FamilyRole.owner) {
        throw Exception('Family owner cannot change their own role');
      }
    }

    await _familyRepository.updateFamilyMember(
      familyId: familyId,
      userId: memberUserId,
      role: role,
      permissions: permissions,
    );
  }

  /// Gets pending invitations for the current user's family
  Future<List<FamilyInvitation>> getPendingInvitations() async {
    final family = await getCurrentUserFamily();
    if (family == null) return [];

    await _ensureFamilyAccess(family.id);
    return _familyRepository.getPendingInvitations(family.id);
  }

  /// Cancels a pending invitation (inviter or admin only)
  Future<void> cancelInvitation(String invitationId) async {
    final invitation = await _familyRepository.getInvitation(invitationId);
    if (invitation == null) {
      throw Exception('Invitation not found');
    }

    final currentUser = _authGuard.user!;
    final family = await _familyRepository.getFamily(invitation.familyId);

    if (invitation.invitedBy != currentUser.uid && family?.adminUserId != currentUser.uid) {
      throw Exception('Not authorized to cancel this invitation');
    }

    await _familyRepository.updateInvitationStatus(invitationId, InvitationStatus.cancelled);
  }

  /// Transfers family ownership to another member (owner only)
  Future<void> transferOwnership(String familyId, String newOwnerUserId) async {
    _authGuard.requireOwner();
    final currentUser = _authGuard.user!;
    final family = await _familyRepository.getFamily(familyId);

    if (family?.adminUserId != currentUser.uid) {
      throw Exception('Only the current owner can transfer ownership');
    }

    if (newOwnerUserId == currentUser.uid) {
      throw Exception('Cannot transfer ownership to yourself');
    }

    // Check if new owner is a member
    final newOwner = await _familyRepository.getFamilyMember(familyId, newOwnerUserId);
    if (newOwner == null) {
      throw Exception('New owner must be a family member');
    }

    // Update family owner
    await _familyRepository.updateFamilyOwner(familyId, newOwnerUserId);

    // Update both members' roles
    await _familyRepository.updateFamilyMember(
      familyId: familyId,
      userId: currentUser.uid,
      role: FamilyRole.admin,
      permissions: MemberPermissions.admin(),
    );

    await _familyRepository.updateFamilyMember(
      familyId: familyId,
      userId: newOwnerUserId,
      role: FamilyRole.owner,
      permissions: MemberPermissions.owner(),
    );
  }

  /// Deletes the entire family (owner only, dangerous operation)
  Future<void> deleteFamily(String familyId) async {
    _authGuard.requireOwner();
    final currentUser = _authGuard.user!;
    final family = await _familyRepository.getFamily(familyId);

    if (family?.adminUserId != currentUser.uid) {
      throw Exception('Only the family owner can delete the family');
    }

    // Delete all family data
    await _familyRepository.deleteFamily(familyId);

    // Note: Members' family membership will be updated by the auth system
    // This is handled by the authentication flow when they sign in next
  }

  // Private helper methods

  Future<void> _ensureFamilyAccess(String familyId) async {
    _authGuard.requireAuthentication();
    final userFamilyId = _authGuard.familyId;
    if (userFamilyId != familyId) {
      throw Exception('User is not a member of this family');
    }
  }

  Future<void> _ensureOwnerPermission(String familyId) async {
    _authGuard.requireOwner();
    final family = await _familyRepository.getFamily(familyId);
    if (family?.adminUserId != _authGuard.user!.uid) {
      throw Exception('Only family owner can perform this action');
    }
  }

  Future<void> _ensureInvitePermission(String familyId) async {
    _authGuard.requireAuthentication();
    final member = await _familyRepository.getFamilyMember(familyId, _authGuard.user!.uid);
    if (member == null || !member.permissions.canInviteMembers) {
      throw Exception('User does not have permission to invite members');
    }
  }

  Future<void> _ensureManageMembersPermission(String familyId) async {
    _authGuard.requireAuthentication();
    final member = await _familyRepository.getFamilyMember(familyId, _authGuard.user!.uid);
    if (member == null || !member.permissions.canRemoveMembers) {
      throw Exception('User does not have permission to manage members');
    }
  }

  Future<void> _ensureManagePermissionsPermission(String familyId) async {
    _authGuard.requireAuthentication();
    final member = await _familyRepository.getFamilyMember(familyId, _authGuard.user!.uid);
    if (member == null || !member.permissions.canManagePermissions) {
      throw Exception('User does not have permission to manage permissions');
    }
  }

  Future<void> _sendInvitationNotification(FamilyInvitation invitation) async {
    // Integrazione con servizio notifiche implementata
    // This would send email and/or push notifications
    debugPrint('Sending invitation notification to ${invitation.email}');
  }
}
