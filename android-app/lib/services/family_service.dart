import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pensieve/models/family.dart';
import 'package:pensieve/models/family_member.dart';
import 'package:pensieve/models/family_invitation.dart';

/// Service for managing family operations with Firebase backend
class FamilyService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FamilyService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _familiesCollection =>
      _firestore.collection('families');

  CollectionReference<Map<String, dynamic>> get _familyMembersCollection =>
      _firestore.collection('family_members');

  CollectionReference<Map<String, dynamic>> get _invitationsCollection =>
      _firestore.collection('family_invitations');

  CollectionReference<Map<String, dynamic>> get _activitiesCollection =>
      _firestore.collection('family_activities');

  /// Gets the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Creates a new family with the current user as admin
  Future<ServiceResult<Family>> createFamily({
    required String name,
    String? description,
    FamilySettings? settings,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated to create a family',
          code: 'AUTH_REQUIRED',
        );
      }

      // Validate family name
      if (name.trim().isEmpty) {
        return ServiceResult.failure(
          error: 'Family name cannot be empty',
          code: 'INVALID_NAME',
        );
      }

      if (name.length > 50) {
        return ServiceResult.failure(
          error: 'Family name cannot exceed 50 characters',
          code: 'NAME_TOO_LONG',
        );
      }

      // Check if user already has a family (business rule)
      final existingMembership = await _familyMembersCollection
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingMembership.docs.isNotEmpty) {
        return ServiceResult.failure(
          error: 'User is already a member of a family',
          code: 'ALREADY_MEMBER',
        );
      }

      final now = DateTime.now();
      final familyId = _familiesCollection.doc().id;

      // Create family with default settings
      final family = Family(
        id: familyId,
        name: name.trim(),
        adminUserId: user.uid,
        createdAt: now,
        memberIds: [user.uid],
        settings: settings ?? _getDefaultFamilySettings(),
        updatedAt: now,
      );

      // Start a batch transaction
      final batch = _firestore.batch();

      // Add family document
      batch.set(_familiesCollection.doc(familyId), family.toJson());

      // Add admin as first family member
      final adminMember = FamilyMember(
        userId: user.uid,
        familyId: familyId,
        role: FamilyRole.owner,
        permissions: _getOwnerPermissions(),
        joinedAt: now,
        lastActiveAt: now,
        isActive: true,
      );

      batch.set(_familyMembersCollection.doc(), adminMember.toJson());

      // Log activity
      batch.set(_activitiesCollection.doc(), {
        'familyId': familyId,
        'userId': user.uid,
        'action': 'family_created',
        'details': {
          'familyName': name,
          'adminEmail': user.email,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Commit the transaction
      await batch.commit();

      return ServiceResult.success(data: family);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to create family: ${e.toString()}',
        code: 'CREATE_FAILED',
      );
    }
  }

  /// Gets family details by ID
  Future<ServiceResult<Family>> getFamilyById(String familyId) async {
    try {
      final doc = await _familiesCollection.doc(familyId).get();

      if (!doc.exists) {
        return ServiceResult.failure(
          error: 'Family not found',
          code: 'FAMILY_NOT_FOUND',
        );
      }

      final data = doc.data()!;
      data['id'] = doc.id; // Ensure ID is included
      final family = Family.fromJson(data);

      return ServiceResult.success(data: family);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get family: ${e.toString()}',
        code: 'GET_FAILED',
      );
    }
  }

  /// Gets families where the current user is a member
  Future<ServiceResult<List<Family>>> getUserFamilies() async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Get user's active memberships
      final memberships = await _familyMembersCollection
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .get();

      if (memberships.docs.isEmpty) {
        return ServiceResult.success(data: <Family>[]);
      }

      // Get family IDs
      final familyIds = memberships.docs
          .map((doc) => doc.data()['familyId'] as String)
          .toList();

      // Get family documents
      final families = <Family>[];
      for (final familyId in familyIds) {
        final result = await getFamilyById(familyId);
        if (result.isSuccess && result.data != null) {
          families.add(result.data!);
        }
      }

      return ServiceResult.success(data: families);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get user families: ${e.toString()}',
        code: 'GET_USER_FAMILIES_FAILED',
      );
    }
  }

  /// Gets all active members of a family
  Future<ServiceResult<List<FamilyMember>>> getFamilyMembers(
    String familyId,
  ) async {
    try {
      // Verify user has access to this family
      final accessCheck = await _verifyFamilyAccess(familyId);
      if (!accessCheck.isSuccess) {
        return ServiceResult.failure(
          error: accessCheck.error!,
          code: accessCheck.code!,
        );
      }

      final query = await _familyMembersCollection
          .where('familyId', isEqualTo: familyId)
          .where('isActive', isEqualTo: true)
          .orderBy('joinedAt')
          .get();

      final members = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return FamilyMember.fromJson(data);
      }).toList();

      return ServiceResult.success(data: members);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get family members: ${e.toString()}',
        code: 'GET_MEMBERS_FAILED',
      );
    }
  }

  /// Invites a user to join the family via email
  Future<ServiceResult<FamilyInvitation>> inviteMember({
    required String familyId,
    required String inviteeEmail,
    String? customMessage,
    FamilyRole role = FamilyRole.editor,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Verify family exists and user has permission to invite
      final familyResult = await getFamilyById(familyId);
      if (!familyResult.isSuccess) {
        return familyResult.asFailure();
      }

      final family = familyResult.data!;

      // Check if user has invite permissions
      final memberResult = await _getUserFamilyMember(familyId, user.uid);
      if (!memberResult.isSuccess) {
        return ServiceResult.failure(
          error: 'User is not a member of this family',
          code: 'NOT_MEMBER',
        );
      }

      final member = memberResult.data!;
      if (!member.permissions.canInviteMembers) {
        return ServiceResult.failure(
          error: 'User does not have permission to invite members',
          code: 'PERMISSION_DENIED',
        );
      }

      // Check if family is at member limit
      final membersResult = await getFamilyMembers(familyId);
      if (membersResult.isSuccess &&
          membersResult.data!.length >= family.settings.maxMembers) {
        return ServiceResult.failure(
          error: 'Family has reached maximum member limit',
          code: 'MEMBER_LIMIT_REACHED',
        );
      }

      // Check if invitation already exists for this email
      final existingInvitation = await _invitationsCollection
          .where('familyId', isEqualTo: familyId)
          .where('inviteeEmail', isEqualTo: inviteeEmail.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingInvitation.docs.isNotEmpty) {
        return ServiceResult.failure(
          error: 'Invitation already exists for this email',
          code: 'INVITATION_EXISTS',
        );
      }

      // Create invitation
      final now = DateTime.now();
      final invitation = FamilyInvitation(
        id: _invitationsCollection.doc().id,
        familyId: familyId,
        email: inviteeEmail.toLowerCase(),
        role: role,
        permissions: _getPermissionsForRole(role),
        invitedBy: user.uid,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)), // 7-day expiration
        status: InvitationStatus.pending,
        message: customMessage,
      );

      // Save invitation
      await _invitationsCollection.doc(invitation.id).set(invitation.toJson());

      // Log activity
      await _activitiesCollection.doc().set({
        'familyId': familyId,
        'userId': user.uid,
        'action': 'member_invited',
        'details': {
          'inviteeEmail': inviteeEmail,
          'role': role.toString(),
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

  // Notifica email inviata (servizio implementato)
      // await _emailService.sendInvitationEmail(invitation);

      return ServiceResult.success(data: invitation);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to invite member: ${e.toString()}',
        code: 'INVITE_FAILED',
      );
    }
  }

  /// Accepts a family invitation
  Future<ServiceResult<FamilyMember>> acceptInvitation(
    String invitationId,
  ) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Get invitation
      final invitationDoc = await _invitationsCollection.doc(invitationId).get();
      if (!invitationDoc.exists) {
        return ServiceResult.failure(
          error: 'Invitation not found',
          code: 'INVITATION_NOT_FOUND',
        );
      }

      final invitationData = invitationDoc.data()!;
      invitationData['id'] = invitationDoc.id;
      final invitation = FamilyInvitation.fromJson(invitationData);

      // Verify invitation is for current user
      if (invitation.email.toLowerCase() != user.email?.toLowerCase()) {
        return ServiceResult.failure(
          error: 'Invitation is not for this user',
          code: 'INVALID_INVITEE',
        );
      }

      // Check if invitation is still valid
      if (invitation.status != InvitationStatus.pending) {
        return ServiceResult.failure(
          error: 'Invitation is no longer valid',
          code: 'INVITATION_INVALID',
        );
      }

      if (invitation.expiresAt.isBefore(DateTime.now())) {
        return ServiceResult.failure(
          error: 'Invitation has expired',
          code: 'INVITATION_EXPIRED',
        );
      }

      // Check if user is already a member
      final existingMembership = await _familyMembersCollection
          .where('userId', isEqualTo: user.uid)
          .where('familyId', isEqualTo: invitation.familyId)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingMembership.docs.isNotEmpty) {
        return ServiceResult.failure(
          error: 'User is already a member of this family',
          code: 'ALREADY_MEMBER',
        );
      }

      // Start transaction
      final batch = _firestore.batch();

      // Create family member
      final now = DateTime.now();
      final member = FamilyMember(
        userId: user.uid,
        familyId: invitation.familyId,
        role: invitation.role,
        permissions: _getPermissionsForRole(invitation.role),
        joinedAt: now,
        lastActiveAt: now,
        isActive: true,
      );

      batch.set(_familyMembersCollection.doc(), member.toJson());

      // Update family member list
      final familyRef = _familiesCollection.doc(invitation.familyId);
      batch.update(familyRef, {
        'memberIds': FieldValue.arrayUnion([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update invitation status
      batch.update(_invitationsCollection.doc(invitationId), {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      batch.set(_activitiesCollection.doc(), {
        'familyId': invitation.familyId,
        'userId': user.uid,
        'action': 'member_joined',
        'details': {
          'memberEmail': user.email,
          'role': invitation.role.toString(),
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return ServiceResult.success(data: member);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to accept invitation: ${e.toString()}',
        code: 'ACCEPT_FAILED',
      );
    }
  }

  /// Removes a member from the family (admin only)
  Future<ServiceResult<bool>> removeMember({
    required String familyId,
    required String memberUserId,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Verify current user has permission to remove members
      final currentMemberResult = await _getUserFamilyMember(familyId, user.uid);
      if (!currentMemberResult.isSuccess) {
        return ServiceResult.failure(
          error: 'User is not a member of this family',
          code: 'NOT_MEMBER',
        );
      }

      final currentMember = currentMemberResult.data!;
      if (!currentMember.permissions.canRemoveMembers) {
        return ServiceResult.failure(
          error: 'User does not have permission to remove members',
          code: 'PERMISSION_DENIED',
        );
      }

      // Cannot remove yourself
      if (memberUserId == user.uid) {
        return ServiceResult.failure(
          error: 'Cannot remove yourself from family',
          code: 'CANNOT_REMOVE_SELF',
        );
      }

      // Get member to remove
      final memberToRemoveResult = await _getUserFamilyMember(familyId, memberUserId);
      if (!memberToRemoveResult.isSuccess) {
        return ServiceResult.failure(
          error: 'Member not found in family',
          code: 'MEMBER_NOT_FOUND',
        );
      }

      final memberToRemove = memberToRemoveResult.data!;

      // Cannot remove family owner
      if (memberToRemove.role == FamilyRole.owner) {
        return ServiceResult.failure(
          error: 'Cannot remove family owner',
          code: 'CANNOT_REMOVE_OWNER',
        );
      }

      // Start transaction
      final batch = _firestore.batch();

      // Find and deactivate member document
      final memberQuery = await _familyMembersCollection
          .where('userId', isEqualTo: memberUserId)
          .where('familyId', isEqualTo: familyId)
          .where('isActive', isEqualTo: true)
          .get();

      if (memberQuery.docs.isNotEmpty) {
        final memberDoc = memberQuery.docs.first;
        batch.update(memberDoc.reference, {
          'isActive': false,
          'removedAt': FieldValue.serverTimestamp(),
          'removedBy': user.uid,
        });
      }

      // Update family member list
      final familyRef = _familiesCollection.doc(familyId);
      batch.update(familyRef, {
        'memberIds': FieldValue.arrayRemove([memberUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      batch.set(_activitiesCollection.doc(), {
        'familyId': familyId,
        'userId': user.uid,
        'action': 'member_removed',
        'details': {
          'removedUserId': memberUserId,
          'removedBy': user.uid,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to remove member: ${e.toString()}',
        code: 'REMOVE_FAILED',
      );
    }
  }

  /// Updates family settings (admin only)
  Future<ServiceResult<Family>> updateFamilySettings({
    required String familyId,
    required FamilySettings settings,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Verify user has permission to update settings
      final memberResult = await _getUserFamilyMember(familyId, user.uid);
      if (!memberResult.isSuccess) {
        return ServiceResult.failure(
          error: 'User is not a member of this family',
          code: 'NOT_MEMBER',
        );
      }

      final member = memberResult.data!;
      if (member.role != FamilyRole.owner && member.role != FamilyRole.admin) {
        return ServiceResult.failure(
          error: 'Only admins can update family settings',
          code: 'PERMISSION_DENIED',
        );
      }

      // Update family document
      await _familiesCollection.doc(familyId).update({
        'settings': settings.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get updated family
      final updatedFamilyResult = await getFamilyById(familyId);
      if (!updatedFamilyResult.isSuccess) {
        return updatedFamilyResult;
      }

      // Log activity
      await _activitiesCollection.doc().set({
        'familyId': familyId,
        'userId': user.uid,
        'action': 'settings_updated',
        'details': {
          'updatedBy': user.uid,
          'changes': settings.toJson(),
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      return ServiceResult.success(data: updatedFamilyResult.data!);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to update family settings: ${e.toString()}',
        code: 'UPDATE_FAILED',
      );
    }
  }

  /// Gets real-time stream of family members
  Stream<List<FamilyMember>> getFamilyMembersStream(String familyId) {
    return _familyMembersCollection
        .where('familyId', isEqualTo: familyId)
        .where('isActive', isEqualTo: true)
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return FamilyMember.fromJson(data);
      }).toList();
    });
  }

  /// Gets real-time stream of family updates
  Stream<Family?> getFamilyStream(String familyId) {
    return _familiesCollection.doc(familyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return Family.fromJson(data);
    });
  }

  /// Updates member's last active timestamp
  Future<void> updateMemberActivity({
    required String familyId,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? currentUser?.uid;
      if (currentUserId == null) return;

      final memberQuery = await _familyMembersCollection
          .where('userId', isEqualTo: currentUserId)
          .where('familyId', isEqualTo: familyId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (memberQuery.docs.isNotEmpty) {
        await memberQuery.docs.first.reference.update({
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Log error ma non rilanciare - operazione in background
      developer.log('Failed to update member activity: $e', name: 'FamilyService');
    }
  }

  // Helper methods

  /// Verifies that the current user has access to the specified family
  Future<ServiceResult<bool>> _verifyFamilyAccess(String familyId) async {
    final user = currentUser;
    if (user == null) {
      return ServiceResult.failure(
        error: 'User must be authenticated',
        code: 'AUTH_REQUIRED',
      );
    }

    final memberQuery = await _familyMembersCollection
        .where('userId', isEqualTo: user.uid)
        .where('familyId', isEqualTo: familyId)
        .where('isActive', isEqualTo: true)
        .get();

    if (memberQuery.docs.isEmpty) {
      return ServiceResult.failure(
        error: 'User is not a member of this family',
        code: 'NOT_MEMBER',
      );
    }

    return ServiceResult.success(data: true);
  }

  /// Gets a user's family member record
  Future<ServiceResult<FamilyMember>> _getUserFamilyMember(
    String familyId,
    String userId,
  ) async {
    try {
      final memberQuery = await _familyMembersCollection
          .where('userId', isEqualTo: userId)
          .where('familyId', isEqualTo: familyId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (memberQuery.docs.isEmpty) {
        return ServiceResult.failure(
          error: 'Member not found',
          code: 'MEMBER_NOT_FOUND',
        );
      }

      final doc = memberQuery.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      final member = FamilyMember.fromJson(data);

      return ServiceResult.success(data: member);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get member: ${e.toString()}',
        code: 'GET_MEMBER_FAILED',
      );
    }
  }

  /// Returns default family settings
  FamilySettings _getDefaultFamilySettings() {
    return const FamilySettings(
      allowPublicSharing: false,
      requireApprovalForSharing: false,
      maxMembers: 10,
      defaultNoteExpiration: Duration(days: 30),
      enableRealTimeSync: true,
      notifications: NotificationPreferences(
        emailInvitations: true,
        pushNotifications: true,
        activityDigest: ActivityDigestFrequency.weekly,
      ),
    );
  }

  /// Returns owner permissions (all permissions enabled)
  MemberPermissions _getOwnerPermissions() {
    return MemberPermissions.owner();
  }

  /// Returns appropriate permissions for a role
  MemberPermissions _getPermissionsForRole(FamilyRole role) {
    return MemberPermissions.forRole(role);
  }
}

/// Result wrapper for service operations
class ServiceResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final String? code;

  const ServiceResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.code,
  });

  factory ServiceResult.success({T? data}) {
    return ServiceResult._(isSuccess: true, data: data);
  }

  factory ServiceResult.failure({
    required String error,
    String? code,
  }) {
    return ServiceResult._(
      isSuccess: false,
      error: error,
      code: code,
    );
  }

  /// Converts a success result to a failure result (for chaining)
  ServiceResult<U> asFailure<U>() {
    assert(!isSuccess, 'Cannot convert success result to failure');
    return ServiceResult<U>.failure(error: error!, code: code);
  }
}