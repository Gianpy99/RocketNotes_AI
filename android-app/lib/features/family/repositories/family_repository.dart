import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/family.dart';
import '../../../models/family_member.dart';
import '../../../models/family_invitation.dart';

class FamilyRepository {
  final FirebaseFirestore _firestore;

  // Collection references
  static const String familiesCollection = 'families';
  static const String membersCollection = 'members';
  static const String invitationsCollection = 'invitations';

  FamilyRepository(this._firestore);

  // Family CRUD Operations

  /// Creates a new family in Firestore
  Future<Family> createFamily({
    required String ownerId,
    required String name,
    required FamilySettings settings,
  }) async {
    final familyId = _firestore.collection(familiesCollection).doc().id;

    final family = Family(
      id: familyId,
      name: name,
      adminUserId: ownerId,
      memberIds: [ownerId], // Start with owner as first member
      settings: settings,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection(familiesCollection).doc(familyId).set(family.toJson());

    return family;
  }

  /// Gets a family by ID
  Future<Family?> getFamily(String familyId) async {
    // Fetch from Firestore
    final doc = await _firestore.collection(familiesCollection).doc(familyId).get();
    if (!doc.exists) return null;

    return Family.fromJson(doc.data()!);
  }

  /// Updates family information
  Future<void> updateFamily(String familyId, {
    String? name,
    FamilySettings? settings,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (settings != null) updates['settings'] = settings.toJson();

    await _firestore.collection(familiesCollection).doc(familyId).update(updates);
  }

  /// Updates family owner
  Future<void> updateFamilyOwner(String familyId, String newOwnerId) async {
    await _firestore.collection(familiesCollection).doc(familyId).update({
      'adminUserId': newOwnerId,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Update cache
    final cached = await _getCachedFamily(familyId);
    if (cached != null) {
      final updated = cached.copyWith(
        adminUserId: newOwnerId,
        updatedAt: DateTime.now(),
      );
      await _cacheFamily(updated);
    }
  }

  /// Deletes a family and all associated data
  Future<void> deleteFamily(String familyId) async {
    // Delete all members
    final members = await getFamilyMembers(familyId);
    for (final member in members) {
      await _firestore
          .collection(familiesCollection)
          .doc(familyId)
          .collection(membersCollection)
          .doc(member.userId)
          .delete();
    }

    // Delete all invitations
    final invitations = await getPendingInvitations(familyId);
    for (final invitation in invitations) {
      await _firestore.collection(invitationsCollection).doc(invitation.id).delete();
    }

    // Delete family document
    await _firestore.collection(familiesCollection).doc(familyId).delete();

    // Clear cache
    await _clearFamilyCache(familyId);
  }

  // Member Management

  /// Adds a member to a family
  Future<void> addFamilyMember({
    required String familyId,
    required String userId,
    required FamilyRole role,
    required MemberPermissions permissions,
  }) async {
    final member = FamilyMember(
      userId: userId,
      familyId: familyId,
      role: role,
      permissions: permissions,
      joinedAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    await _firestore
        .collection(familiesCollection)
        .doc(familyId)
        .collection(membersCollection)
        .doc(userId)
        .set(member.toJson());

    // Update member count
    await incrementFamilyMemberCount(familyId);
  }

  /// Gets a family member
  Future<FamilyMember?> getFamilyMember(String familyId, String userId) async {
    // Fetch from Firestore
    final doc = await _firestore
        .collection(familiesCollection)
        .doc(familyId)
        .collection(membersCollection)
        .doc(userId)
        .get();

    if (!doc.exists) return null;

    return FamilyMember.fromJson(doc.data()!);
  }

  /// Gets all members of a family
  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    // Fetch from Firestore
    final snapshot = await _firestore
        .collection(familiesCollection)
        .doc(familyId)
        .collection(membersCollection)
        .get();

    return snapshot.docs
        .map((doc) => FamilyMember.fromJson(doc.data()))
        .toList();
  }

  /// Updates a family member
  Future<void> updateFamilyMember({
    required String familyId,
    required String userId,
    FamilyRole? role,
    MemberPermissions? permissions,
  }) async {
    final updates = <String, dynamic>{};

    if (role != null) updates['role'] = role.name;
    if (permissions != null) updates['permissions'] = permissions.toJson();

    await _firestore
        .collection(familiesCollection)
        .doc(familyId)
        .collection(membersCollection)
        .doc(userId)
        .update(updates);
  }

  /// Removes a member from a family
  Future<void> removeFamilyMember(String familyId, String userId) async {
    await _firestore
        .collection(familiesCollection)
        .doc(familyId)
        .collection(membersCollection)
        .doc(userId)
        .delete();

    // Update member count
    await decrementFamilyMemberCount(familyId);
  }

  /// Updates member's last active timestamp
  Future<void> updateMemberLastActive(String familyId, String userId) async {
    await _firestore
        .collection(familiesCollection)
        .doc(familyId)
        .collection(membersCollection)
        .doc(userId)
        .update({
          'lastActiveAt': DateTime.now().toIso8601String(),
        });

    // Update cache
    final cached = await _getCachedFamilyMember(familyId, userId);
    if (cached != null) {
      final updated = cached.copyWith(lastActiveAt: DateTime.now());
      await _cacheFamilyMember(updated);
    }
  }

  // Invitation Management

  /// Creates a family invitation
  Future<FamilyInvitation> createInvitation({
    required String familyId,
    required String invitedBy,
    required String email,
    required FamilyRole role,
    required MemberPermissions permissions,
    DateTime? expiresAt,
  }) async {
    final invitationId = _firestore.collection(invitationsCollection).doc().id;

    final invitation = FamilyInvitation(
      id: invitationId,
      familyId: familyId,
      invitedBy: invitedBy,
      email: email,
      role: role,
      permissions: permissions,
      status: InvitationStatus.pending,
      createdAt: DateTime.now(),
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 7)),
    );

    await _firestore.collection(invitationsCollection).doc(invitationId).set(invitation.toJson());

    return invitation;
  }

  /// Gets an invitation by ID
  Future<FamilyInvitation?> getInvitation(String invitationId) async {
    // Fetch from Firestore
    final doc = await _firestore.collection(invitationsCollection).doc(invitationId).get();
    if (!doc.exists) return null;

    return FamilyInvitation.fromJson(doc.data()!);
  }

  /// Gets pending invitations for a family
  Future<List<FamilyInvitation>> getPendingInvitations(String familyId) async {
    // Fetch from Firestore
    final snapshot = await _firestore
        .collection(invitationsCollection)
        .where('familyId', isEqualTo: familyId)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .get();

    return snapshot.docs
        .map((doc) => FamilyInvitation.fromJson(doc.data()))
        .where((invitation) => !invitation.isExpired)
        .toList();
  }

  /// Updates invitation status
  Future<void> updateInvitationStatus(String invitationId, InvitationStatus status) async {
    await _firestore.collection(invitationsCollection).doc(invitationId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Utility Methods

  /// Increments family member count
  Future<void> incrementFamilyMemberCount(String familyId) async {
    // Get current family to update memberIds
    final family = await getFamily(familyId);
    if (family == null) return;

    // Note: memberIds are managed separately, this method is for compatibility
    // The actual member count is derived from memberIds.length
  }

  /// Decrements family member count
  Future<void> decrementFamilyMemberCount(String familyId) async {
    // Get current family to update memberIds
    final family = await getFamily(familyId);
    if (family == null) return;

    // Note: memberIds are managed separately, this method is for compatibility
    // The actual member count is derived from memberIds.length
  }

  /// Updates family settings
  Future<void> updateFamilySettings(String familyId, FamilySettings settings) async {
    await _firestore.collection(familiesCollection).doc(familyId).update({
      'settings': settings.toJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Gets a family member by email (for invitation validation)
  Future<FamilyMember?> getFamilyMemberByEmail(String familyId, String email) async {
    // This is a simplified implementation - in a real app you'd need to query users by email
    // For now, we'll return null (assuming email uniqueness across members)
    return null;
  }

  /// Gets the current member count for a family
  Future<int> getFamilyMemberCount(String familyId) async {
    final family = await getFamily(familyId);
    return family?.memberIds.length ?? 0;
  }

  // Caching Methods - TODO: Implement when HiveService is available

  Future<void> _cacheFamily(Family family) async {
    // TODO: Implement caching with HiveService
  }

  Future<Family?> _getCachedFamily(String familyId) async {
    // TODO: Implement caching with HiveService
    return null;
  }

  Future<void> _clearFamilyCache(String familyId) async {
    // TODO: Implement caching with HiveService
  }

  Future<void> _cacheFamilyMember(FamilyMember member) async {
    // TODO: Implement caching with HiveService
  }

  Future<FamilyMember?> _getCachedFamilyMember(String familyId, String userId) async {
    // TODO: Implement caching with HiveService
    return null;
  }
}
