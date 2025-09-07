/// Riverpod Providers for Family State Management
///
/// This file contains all the Riverpod providers for managing family-related state:
/// - Family data and current family selection
/// - Family members and their permissions
/// - Family invitations and pending requests
/// - Shared notes and permissions
/// - Authentication state for family features

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_config.dart';
import '../../../models/family_member.dart';
import '../../../models/shared_note.dart';
import '../../../models/family_invitation.dart';
import '../services/family_service.dart';
import '../repositories/family_repository.dart';
import './auth_providers.dart';

/// Provider for Firebase Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return FamilyFirebaseConfig.auth.authStateChanges();
});

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );
});

/// Provider for current user's family ID
final currentUserFamilyIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final userDoc = await FamilyFirebaseConfig.firestore
      .collection('users')
      .doc(user.uid)
      .get();

  return userDoc.data()?['familyId'] as String?;
});

/// Provider for current family data
final currentFamilyProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final familyId = await ref.watch(currentUserFamilyIdProvider.future);
  if (familyId == null) return null;

  final familyDoc = await FamilyFirebaseConfig.familiesRef.doc(familyId).get();
  return familyDoc.data();
});

/// Provider for family members
final familyMembersProvider = FutureProvider<List<FamilyMember>>((ref) async {
  final familyId = await ref.watch(currentUserFamilyIdProvider.future);
  if (familyId == null) return [];

  final membersSnapshot = await FamilyFirebaseConfig.firestore
      .collection('family_members')
      .where('familyId', isEqualTo: familyId)
      .get();

  return membersSnapshot.docs
      .map((doc) => FamilyMember.fromJson(doc.data()..['id'] = doc.id))
      .toList();
});

/// Provider for pending family invitations
final pendingInvitationsProvider = FutureProvider<List<FamilyInvitation>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final invitationsSnapshot = await FamilyFirebaseConfig.firestore
      .collection('family_invitations')
      .where('email', isEqualTo: user.email)
      .where('status', isEqualTo: 'pending')
      .get();

  return invitationsSnapshot.docs
      .map((doc) => FamilyInvitation.fromJson(doc.data()..['id'] = doc.id))
      .toList();
});

/// Provider for shared notes in current family
final sharedNotesProvider = FutureProvider<List<SharedNote>>((ref) async {
  final familyId = await ref.watch(currentUserFamilyIdProvider.future);
  if (familyId == null) return [];

  final notesSnapshot = await FamilyFirebaseConfig.firestore
      .collection('shared_notes')
      .where('familyId', isEqualTo: familyId)
      .orderBy('sharedAt', descending: true)
      .get();

  return notesSnapshot.docs
      .map((doc) => SharedNote.fromJson(doc.data()..['id'] = doc.id))
      .toList();
});

/// Provider for user's permissions in current family
final userPermissionsProvider = FutureProvider<Map<String, bool>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final familyId = await ref.watch(currentUserFamilyIdProvider.future);

  if (user == null || familyId == null) return {};

  final memberDoc = await FamilyFirebaseConfig.firestore
      .collection('family_members')
      .doc('${familyId}_${user.uid}')
      .get();

  return Map<String, bool>.from(memberDoc.data()?['permissions'] ?? {});
});

/// State notifier for family creation
class FamilyCreationNotifier extends StateNotifier<AsyncValue<String?>> {
  FamilyCreationNotifier() : super(const AsyncValue.data(null));

  Future<void> createFamily({
    required String name,
    required String description,
    required Map<String, dynamic> settings,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = FamilyFirebaseConfig.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final familyData = {
        'name': name,
        'description': description,
        'ownerId': user.uid,
        'settings': settings,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
        'pendingInvitations': 0,
      };

      final familyRef = await FamilyFirebaseConfig.familiesRef.add(familyData);

      // Add owner as first member
      await FamilyFirebaseConfig.familyMembersRef.doc('${familyRef.id}_${user.uid}').set({
        'familyId': familyRef.id,
        'userId': user.uid,
        'email': user.email,
        'role': 'owner',
        'permissions': {
          'canInviteMembers': true,
          'canManageMembers': true,
          'canShareNotes': true,
          'canManagePermissions': true,
          'canViewAuditLogs': true,
        },
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Update user's family ID
      await FamilyFirebaseConfig.firestore
          .collection('users')
          .doc(user.uid)
          .set({'familyId': familyRef.id}, SetOptions(merge: true));

      state = AsyncValue.data(familyRef.id);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final familyCreationProvider = StateNotifierProvider<FamilyCreationNotifier, AsyncValue<String?>>((ref) {
  return FamilyCreationNotifier();
});

/// State notifier for family invitations
class FamilyInvitationNotifier extends StateNotifier<AsyncValue<void>> {
  FamilyInvitationNotifier() : super(const AsyncValue.data(null));

  Future<void> sendInvitation({
    required String familyId,
    required String email,
    required String role,
    required Map<String, bool> permissions,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = FamilyFirebaseConfig.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final invitationData = {
        'familyId': familyId,
        'email': email,
        'role': role,
        'permissions': permissions,
        'invitedBy': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
      };

      await FamilyFirebaseConfig.familyInvitationsRef.add(invitationData);

      // Update family's pending invitations count
      await FamilyFirebaseConfig.familiesRef.doc(familyId).update({
        'pendingInvitations': FieldValue.increment(1),
      });

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    state = const AsyncValue.loading();

    try {
      final user = FamilyFirebaseConfig.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final invitationDoc = await FamilyFirebaseConfig.familyInvitationsRef.doc(invitationId).get();
      if (!invitationDoc.exists) throw Exception('Invitation not found');

      final invitationData = invitationDoc.data()!;
      final familyId = invitationData['familyId'] as String;

      // Add user to family
      await FamilyFirebaseConfig.familyMembersRef.doc('${familyId}_${user.uid}').set({
        'familyId': familyId,
        'userId': user.uid,
        'email': user.email,
        'role': invitationData['role'],
        'permissions': invitationData['permissions'],
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Update invitation status
      await FamilyFirebaseConfig.familyInvitationsRef.doc(invitationId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Update family member count
      await FamilyFirebaseConfig.familiesRef.doc(familyId).update({
        'memberCount': FieldValue.increment(1),
        'pendingInvitations': FieldValue.increment(-1),
      });

      // Update user's family ID
      await FamilyFirebaseConfig.firestore
          .collection('users')
          .doc(user.uid)
          .set({'familyId': familyId}, SetOptions(merge: true));

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final familyInvitationProvider = StateNotifierProvider<FamilyInvitationNotifier, AsyncValue<void>>((ref) {
  return FamilyInvitationNotifier();
});

/// Provider for FamilyRepository
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository(FamilyFirebaseConfig.firestore);
});

/// Provider for FamilyService
final familyServiceProvider = Provider<FamilyService>((ref) {
  final repository = ref.watch(familyRepositoryProvider);
  final authGuard = ref.watch(authGuardProvider);
  return FamilyService(repository, authGuard);
});
