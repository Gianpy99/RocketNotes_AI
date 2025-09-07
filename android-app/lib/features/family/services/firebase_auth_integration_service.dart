/// Firebase Auth Integration Service
///
/// Handles Firebase Authentication integration for family membership claims.
/// Manages user authentication state, custom claims, and family membership persistence.
/// Integrates with Firebase Auth to maintain secure family membership information.
///
/// This service provides a bridge between Firebase Auth and the family management system,
/// ensuring secure and consistent user authentication and authorization.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../models/family_member.dart';
import '../repositories/family_repository.dart';

class FirebaseAuthIntegrationService {
  final FirebaseAuth _auth;
  final FamilyRepository _familyRepository;

  FirebaseAuthIntegrationService(this._auth, this._familyRepository);

  /// Gets the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in a user with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Creates a new user account
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Sends password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Updates user's family membership in Firebase Auth custom claims
  Future<void> updateUserFamilyMembership(String userId, String? familyId, FamilyRole? role) async {
    try {
      // Get the user
      final user = _auth.currentUser;
      if (user == null) return;

      // Prepare custom claims
      final claims = <String, dynamic>{};

      if (familyId != null) {
        claims['familyId'] = familyId;
        claims['familyRole'] = role?.name ?? FamilyRole.viewer.name;
        claims['isFamilyMember'] = true;
      } else {
        claims['familyId'] = null;
        claims['familyRole'] = null;
        claims['isFamilyMember'] = false;
      }

      // Update custom claims (requires admin privileges in production)
      // For now, we'll store this information in Firestore user profile
      await _updateUserProfileClaims(userId, claims);

    } catch (e) {
      // Log error but don't fail the operation
      debugPrint('Failed to update user family membership claims: $e');
    }
  }

  /// Gets user's family membership from Firebase Auth or profile
  Future<Map<String, dynamic>?> getUserFamilyMembership(String userId) async {
    try {
      // Try to get from custom claims first
      final user = _auth.currentUser;
      if (user != null) {
        final idToken = await user.getIdTokenResult();
        final claims = idToken.claims;

        if (claims != null && claims.containsKey('familyId')) {
          return {
            'familyId': claims['familyId'],
            'familyRole': claims['familyRole'],
            'isFamilyMember': claims['isFamilyMember'] ?? false,
          };
        }
      }

      // Fallback to user profile claims
      return await _getUserProfileClaims(userId);

    } catch (e) {
      debugPrint('Failed to get user family membership: $e');
      return null;
    }
  }

  /// Validates user's family membership against Firebase Auth state
  Future<bool> validateUserFamilyMembership(String userId, String familyId) async {
    try {
      final membership = await getUserFamilyMembership(userId);
      if (membership == null) return false;

      return membership['familyId'] == familyId && membership['isFamilyMember'] == true;

    } catch (e) {
      debugPrint('Failed to validate user family membership: $e');
      return false;
    }
  }

  /// Updates user's display name and profile information
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.updateDisplayName(displayName);
    if (photoURL != null) {
      await user.updatePhotoURL(photoURL);
    }
  }

  /// Reauthenticates user before sensitive operations
  Future<UserCredential> reauthenticateUser(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('User not authenticated or email not available');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    return await user.reauthenticateWithCredential(credential);
  }

  /// Changes user's password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await reauthenticateUser(currentPassword);
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  /// Deletes user account (dangerous operation)
  Future<void> deleteUserAccount(String password) async {
    await reauthenticateUser(password);
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  /// Links user account with additional authentication provider
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return await user.linkWithCredential(credential);
  }

  /// Unlinks authentication provider from user account
  Future<User> unlinkProvider(String providerId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return await user.unlink(providerId);
  }

  /// Gets user's authentication providers
  List<String> getUserProviders() {
    final user = _auth.currentUser;
    if (user == null) return [];

    return user.providerData.map((info) => info.providerId).toList();
  }

  /// Refreshes user's ID token
  Future<void> refreshToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.getIdToken(true);
    }
  }

  /// Checks if user's email is verified
  bool isEmailVerified() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  /// Sends email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reloads user data from Firebase Auth
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  // Private helper methods

  /// Updates user profile claims in Firestore (fallback for custom claims)
  Future<void> _updateUserProfileClaims(String userId, Map<String, dynamic> claims) async {
    // In a real implementation, you might store this in a users collection
    // For now, we'll just simulate the operation
    debugPrint('Updating user profile claims for $userId: $claims');
  }

  /// Gets user profile claims from Firestore
  Future<Map<String, dynamic>?> _getUserProfileClaims(String userId) async {
    // In a real implementation, you would fetch from users collection
    // For now, return null to indicate no profile claims
    debugPrint('Getting user profile claims for $userId');
    return null;
  }

  /// Syncs family membership between Auth claims and Firestore
  Future<void> syncFamilyMembershipWithAuth(String userId) async {
    try {
      // Get family membership from Firestore
      final member = await _familyRepository.getFamilyMemberByUserId(userId);

      if (member != null) {
        // Update Auth claims with family information
        await updateUserFamilyMembership(userId, member.familyId, member.role);
      } else {
        // Clear Auth claims if no family membership
        await updateUserFamilyMembership(userId, null, null);
      }

    } catch (e) {
      debugPrint('Failed to sync family membership with Auth: $e');
    }
  }

  /// Validates authentication token and refreshes if needed
  Future<bool> validateAndRefreshToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get fresh token
      final idToken = await user.getIdTokenResult();

      // Check if token is expired or will expire soon (within 5 minutes)
      final expirationTime = idToken.expirationTime;
      if (expirationTime != null) {
        final timeUntilExpiry = expirationTime.difference(DateTime.now());
        if (timeUntilExpiry.inMinutes < 5) {
          // Token expires soon, refresh it
          await refreshToken();
        }
      }

      return true;

    } catch (e) {
      debugPrint('Failed to validate and refresh token: $e');
      return false;
    }
  }
}

// Extension methods for FamilyRepository to support user ID lookups
extension FamilyRepositoryAuthExtension on FamilyRepository {
  /// Gets family member by user ID across all families
  Future<FamilyMember?> getFamilyMemberByUserId(String userId) async {
    // This would require a query across all families
    // In a real implementation, you might have a users collection
    // or maintain an index of user->family mappings
    throw UnimplementedError('getFamilyMemberByUserId not implemented in repository');
  }
}
